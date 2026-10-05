package com.codelearn.study

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.security.NoSuchAlgorithmException
import java.security.SecureRandom
import java.util.Locale
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/**
 * 离线多语言代码沙箱。
 *
 * JavaScript / TypeScript / Python / Lua / SQL / JSON 的运行时全部以 JS 形式
 * 内置在 APK 的 assets 中。原生层现场拼接页面（运行时内联、用户代码转义），
 * 写到应用缓存目录后用 WebView 以 file:// 打开：这样既避免超大内联页面走
 * data: 通道，也让 Brython 在 file:// 下的标准库导入能被正确修复。
 *
 * WebView 禁止一切网络加载、禁止 file:// 页面读取其它本地文件，
 * 执行结束或超时后立即销毁并删除临时页面。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "code_learn_app/sandbox"
    private val backupCryptoChannelName = "code_learn_app/backup_crypto"
    private val backupFileChannelName = "code_learn_app/backup_files"
    private val contentPackChannelName = "code_learn_app/content_pack"
    private val shareChannelName = "code_learn_app/share"
    private val ttsChannelName = "code_learn_app/tts"
    private val assetCache = HashMap<String, String>()
    private var activeWebView: WebView? = null
    private var activeTimeout: Runnable? = null
    private var activePageFile: File? = null
    private var pendingContentPackResult: MethodChannel.Result? = null
    private var pendingBackupOpenResult: MethodChannel.Result? = null
    private var pendingBackupCreateResult: MethodChannel.Result? = null
    private var pendingBackupFolderResult: MethodChannel.Result? = null
    private var pendingBackupPayload: String? = null
    private val backupPrefs by lazy {
        getSharedPreferences("code_learn_backup", MODE_PRIVATE)
    }
    private var ttsChannel: MethodChannel? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsReady = false
    private var pendingTtsText: String? = null
    private var pendingTtsLocale: String? = null
    private var pendingTtsResult: MethodChannel.Result? = null
    private var activeTtsLastUtteranceId: String? = null

    /** 语言 -> 页面模板 + 需要内联的运行时文件（相对 assets/sandbox）。 */
    private data class SandboxSpec(val harness: String, val runtimes: List<String>)

    private val specs = mapOf(
        "javascript" to SandboxSpec("javascript.html", emptyList()),
        "typescript" to SandboxSpec(
            "typescript.html",
            listOf("sucrase/sucrase.bundle.js"),
        ),
        "python" to SandboxSpec(
            "python.html",
            listOf("brython/brython.js", "brython/brython_stdlib.js"),
        ),
        "lua" to SandboxSpec("lua.html", listOf("fengari/fengari-web.bundle.js")),
        "sql" to SandboxSpec(
            "sql.html",
            listOf("sqljs/sql-wasm.js", "sqljs/sql-wasm-binary.js"),
        ),
        "json" to SandboxSpec("json.html", emptyList()),
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // 兼容早期只支持 JavaScript 的调用。
                    "runJs" -> runCode(
                        "javascript",
                        call.argument<String>("code") ?: "",
                        result,
                    )
                    "runCode" -> runCode(
                        call.argument<String>("language") ?: "javascript",
                        call.argument<String>("code") ?: "",
                        result,
                    )
                    "destroySandbox" -> {
                        destroySandbox()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 备份加密使用系统标准库完成，不引入第三方加密依赖。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backupCryptoChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "encrypt" -> {
                        val plainText = call.argument<String>("plainText")
                        val password = call.argument<String>("password")
                        if (plainText == null || password.isNullOrEmpty()) {
                            result.error("invalid_args", "Missing plainText or password", null)
                        } else {
                            try {
                                result.success(encryptBackup(plainText, password))
                            } catch (error: Exception) {
                                result.error("encrypt_failed", error.message ?: "encrypt failed", null)
                            }
                        }
                    }
                    "decrypt" -> {
                        val payload = call.argument<String>("payload")
                        val password = call.argument<String>("password")
                        if (payload == null || password.isNullOrEmpty()) {
                            result.error("invalid_args", "Missing payload or password", null)
                        } else {
                            try {
                                result.success(decryptBackup(payload, password))
                            } catch (error: Exception) {
                                result.error("decrypt_failed", error.message ?: "decrypt failed", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 离线内容包：只调用系统文件选择器读取 JSON，不访问网络。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, contentPackChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickJsonFile" -> pickContentPackFile(result)
                    else -> result.notImplemented()
                }
            }

        // 通用文本分享：代码块与笔记导出走系统分享面板，不访问网络。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> shareText(
                        call.argument<String>("text"),
                        call.argument<String>("subject"),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }

        // 学习备份：SAF 另存为 / 文件选择器 / FileProvider 分享。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backupFileChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBackup" -> openBackupFile(result)
                    "saveBackup" -> saveBackupFile(
                        call.argument<String>("payload"),
                        call.argument<String>("suggestedName"),
                        result,
                    )
                    "shareBackup" -> shareBackupFile(
                        call.argument<String>("payload"),
                        call.argument<String>("suggestedName"),
                        result,
                    )
                    "pickBackupFolder" -> pickBackupFolder(result)
                    "getBackupFolder" -> result.success(
                        backupPrefs.getString(BACKUP_TREE_KEY, null),
                    )
                    "clearBackupFolder" -> clearBackupFolder(result)
                    "writeAutoBackup" -> writeAutoBackup(
                        call.argument<String>("payload"),
                        call.argument<String>("suggestedName"),
                        call.argument<Int>("keepCount") ?: DEFAULT_BACKUP_KEEP,
                        result,
                    )
                    "listAutoBackups" -> listAutoBackups(result)
                    else -> result.notImplemented()
                }
            }

        // 离线朗读：使用系统内置 TextToSpeech，不引入网络权限或云端语音依赖。
        val tts = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ttsChannelName)
        ttsChannel = tts
        tts.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(ttsReady && textToSpeech != null)
                "speak" -> {
                    val text = call.argument<String>("text")?.trim().orEmpty()
                    val localeCode = call.argument<String>("locale") ?: "zh"
                    if (text.isEmpty()) {
                        result.success(false)
                    } else if (ttsReady) {
                        result.success(speakText(text, localeCode))
                    } else if (textToSpeech == null) {
                        initializeTts()
                        pendingTtsText = text
                        pendingTtsLocale = localeCode
                        pendingTtsResult?.success(false)
                        pendingTtsResult = result
                    } else {
                        pendingTtsText = text
                        pendingTtsLocale = localeCode
                        pendingTtsResult?.success(false)
                        pendingTtsResult = result
                    }
                }
                "stop" -> {
                    stopText()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** 首次调用时初始化系统语音引擎；初始化完成后立即处理排队的请求。 */
    private fun initializeTts() {
        if (textToSpeech != null) return
        textToSpeech = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) {
                textToSpeech?.setOnUtteranceProgressListener(
                    object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) = Unit

                        override fun onDone(utteranceId: String?) {
                            if (utteranceId != activeTtsLastUtteranceId) return
                            activeTtsLastUtteranceId = null
                            notifyTtsFinished("onDone")
                        }

                        @Deprecated("Deprecated in Java")
                        override fun onError(utteranceId: String?) {
                            activeTtsLastUtteranceId = null
                            notifyTtsFinished("onError")
                        }
                    },
                )
            }

            val queuedText = pendingTtsText
            val queuedLocale = pendingTtsLocale ?: "zh"
            val queuedResult = pendingTtsResult
            pendingTtsText = null
            pendingTtsLocale = null
            pendingTtsResult = null
            if (queuedResult != null) {
                queuedResult.success(
                    if (ttsReady && queuedText != null) {
                        speakText(queuedText, queuedLocale)
                    } else {
                        false
                    },
                )
            }
        }
    }

    /** 按系统最大输入长度分片，避免长篇教程被引擎截断。 */
    private fun speakText(text: String, localeCode: String): Boolean {
        val engine = textToSpeech ?: return false
        val language = if (localeCode == "en") Locale.US else Locale.SIMPLIFIED_CHINESE
        val availability = engine.setLanguage(language)
        if (
            availability == TextToSpeech.LANG_MISSING_DATA ||
            availability == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            return false
        }

        engine.stop()
        val maxLength = TextToSpeech.getMaxSpeechInputLength().coerceAtMost(3500)
        val prefix = "code-learn-${System.currentTimeMillis()}"
        var start = 0
        var chunkIndex = 0
        while (start < text.length) {
            val end = (start + maxLength).coerceAtMost(text.length)
            val chunk = text.substring(start, end)
            val utteranceId = "$prefix-$chunkIndex"
            activeTtsLastUtteranceId = utteranceId
            val queueMode = if (chunkIndex == 0) {
                TextToSpeech.QUEUE_FLUSH
            } else {
                TextToSpeech.QUEUE_ADD
            }
            val params = Bundle().apply {
                putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
            }
            val speechResult = engine.speak(chunk, queueMode, params, utteranceId)
            if (speechResult == TextToSpeech.ERROR) {
                activeTtsLastUtteranceId = null
                return false
            }
            start = end
            chunkIndex++
        }
        return chunkIndex > 0
    }

    private fun stopText() {
        activeTtsLastUtteranceId = null
        textToSpeech?.stop()
    }

    private fun notifyTtsFinished(method: String) {
        Handler(Looper.getMainLooper()).post {
            ttsChannel?.invokeMethod(method, null)
        }
    }

    /**
     * 通用文本分享：代码块、笔记导出等纯文本内容走这里。
     *
     * 只依赖系统 ACTION_SEND，不申请额外权限；分享面板不可用时返回 false，
     * Dart 侧会退回复制到剪贴板。
     */
    private fun shareText(
        text: String?,
        subject: String?,
        result: MethodChannel.Result,
    ) {
        if (text.isNullOrEmpty()) {
            result.success(false)
            return
        }
        if (text.toByteArray(Charsets.UTF_8).size > MAX_SHARE_TEXT_BYTES) {
            result.success(false)
            return
        }
        try {
            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                if (!subject.isNullOrEmpty()) {
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                }
            }
            startActivity(Intent.createChooser(sendIntent, subject ?: "分享"))
            result.success(true)
        } catch (error: Exception) {
            result.success(false)
        }
    }

    private fun pickContentPackFile(result: MethodChannel.Result) {
        // 内容包、备份导入、备份导出共用系统文件选择器；
        // 任意一个还挂着未返回的结果时都不能再开新选择器。
        if (hasPendingFileOperation()) {
            result.error("picker_busy", "A file picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "text/json", "text/plain"),
            )
        }
        pendingContentPackResult = result
        try {
            startActivityForResult(intent, CONTENT_PACK_REQUEST)
        } catch (error: Exception) {
            pendingContentPackResult = null
            result.error("picker_unavailable", error.message ?: "picker unavailable", null)
        }
    }

    private fun openBackupFile(result: MethodChannel.Result) {
        if (hasPendingFileOperation()) {
            result.error("picker_busy", "A file picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "text/json", "text/plain"),
            )
        }
        pendingBackupOpenResult = result
        try {
            startActivityForResult(intent, BACKUP_OPEN_REQUEST)
        } catch (error: Exception) {
            pendingBackupOpenResult = null
            result.error("picker_unavailable", error.message ?: "picker unavailable", null)
        }
    }

    private fun saveBackupFile(
        payload: String?,
        suggestedName: String?,
        result: MethodChannel.Result,
    ) {
        if (hasPendingFileOperation()) {
            result.error("picker_busy", "A file picker is already open", null)
            return
        }
        if (payload.isNullOrEmpty()) {
            result.error("empty_backup", "Backup payload is empty", null)
            return
        }
        if (payload.toByteArray(Charsets.UTF_8).size > MAX_BACKUP_BYTES) {
            result.error("backup_too_large", "Backup exceeds 16 MB", null)
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, safeBackupName(suggestedName))
        }
        pendingBackupCreateResult = result
        pendingBackupPayload = payload
        try {
            startActivityForResult(intent, BACKUP_CREATE_REQUEST)
        } catch (error: Exception) {
            pendingBackupCreateResult = null
            pendingBackupPayload = null
            result.error("picker_unavailable", error.message ?: "picker unavailable", null)
        }
    }

    private fun shareBackupFile(
        payload: String?,
        suggestedName: String?,
        result: MethodChannel.Result,
    ) {
        if (payload.isNullOrEmpty()) {
            result.error("empty_backup", "Backup payload is empty", null)
            return
        }
        if (payload.toByteArray(Charsets.UTF_8).size > MAX_BACKUP_BYTES) {
            result.error("backup_too_large", "Backup exceeds 16 MB", null)
            return
        }
        try {
            val directory = File(cacheDir, BACKUP_SHARE_DIR).apply {
                if (exists()) deleteRecursively()
                mkdirs()
            }
            val file = File(directory, safeBackupName(suggestedName))
            file.writeText(payload, Charsets.UTF_8)
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file,
            )
            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/json"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TITLE, file.name)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(sendIntent, "分享学习备份"))
            result.success(true)
        } catch (error: Exception) {
            result.error("share_failed", error.message ?: "share failed", null)
        }
    }

    /** 让用户选择一个长期授权的备份目录（SAF 目录授权）。 */
    private fun pickBackupFolder(result: MethodChannel.Result) {
        if (hasPendingFileOperation()) {
            result.error("picker_busy", "A file picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        pendingBackupFolderResult = result
        try {
            startActivityForResult(intent, BACKUP_FOLDER_REQUEST)
        } catch (error: Exception) {
            pendingBackupFolderResult = null
            result.error(
                "picker_unavailable",
                error.message ?: "picker unavailable",
                null,
            )
        }
    }

    private fun clearBackupFolder(result: MethodChannel.Result) {
        val stored = backupPrefs.getString(BACKUP_TREE_KEY, null)
        if (stored != null) {
            try {
                contentResolver.releasePersistableUriPermission(
                    Uri.parse(stored),
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
            } catch (_: Exception) {
                // 权限可能已经被系统回收，忽略即可。
            }
        }
        backupPrefs.edit().remove(BACKUP_TREE_KEY).apply()
        result.success(true)
    }

    /** 把一份备份写入已授权的 SAF 目录，并清理超出保留份数的旧文件。 */
    private fun writeAutoBackup(
        payload: String?,
        suggestedName: String?,
        keepCount: Int,
        result: MethodChannel.Result,
    ) {
        if (payload.isNullOrEmpty()) {
            result.error("empty_backup", "Backup payload is empty", null)
            return
        }
        if (payload.toByteArray(Charsets.UTF_8).size > MAX_BACKUP_BYTES) {
            result.error("backup_too_large", "Backup exceeds 16 MB", null)
            return
        }
        val stored = backupPrefs.getString(BACKUP_TREE_KEY, null)
        if (stored == null) {
            // 未选择目录时返回 null，由 Dart 侧提示用户先选择。
            result.success(null)
            return
        }
        val treeUri = Uri.parse(stored)
        try {
            val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
            val parentUri = DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                treeDocumentId,
            )
            val fileName = safeBackupName(suggestedName)
            val documentUri = DocumentsContract.createDocument(
                contentResolver,
                parentUri,
                "application/json",
                fileName,
            ) ?: throw IllegalArgumentException("create document failed")
            contentResolver.openOutputStream(documentUri, "wt")?.use { stream ->
                stream.write(payload.toByteArray(Charsets.UTF_8))
            } ?: throw IllegalArgumentException("empty content URI")

            val deleted = pruneAutoBackups(treeUri, keepCount)
            result.success(
                mapOf(
                    "name" to fileName,
                    "deleted" to deleted,
                ),
            )
        } catch (error: Exception) {
            result.error(
                "auto_backup_failed",
                error.message ?: "auto backup failed",
                null,
            )
        }
    }

    /** 列出备份目录中由本 App 写入的备份文件（按修改时间倒序）。 */
    private fun listAutoBackups(result: MethodChannel.Result) {
        val stored = backupPrefs.getString(BACKUP_TREE_KEY, null)
        if (stored == null) {
            result.success(emptyList<Map<String, Any>>())
            return
        }
        val treeUri = Uri.parse(stored)
        try {
            val entries = queryAutoBackups(treeUri)
            result.success(
                entries.map { entry ->
                    mapOf<String, Any>(
                        "name" to entry.first,
                        "modifiedAt" to entry.second,
                    )
                },
            )
        } catch (error: Exception) {
            result.error(
                "auto_backup_list_failed",
                error.message ?: "list failed",
                null,
            )
        }
    }

    /** 读取目录内符合命名规范的备份文件：文件名 + 修改时间（毫秒）。 */
    private fun queryAutoBackups(treeUri: Uri): List<Pair<String, Long>> {
        val collection = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val entries = mutableListOf<Pair<String, Long>>()
        contentResolver.query(
            collection,
            arrayOf(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )
            val modifiedIndex = cursor.getColumnIndex(
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            )
            while (cursor.moveToNext()) {
                val name = if (nameIndex >= 0) cursor.getString(nameIndex) else null
                if (name == null || !isBackupFileName(name)) continue
                val modified = if (modifiedIndex >= 0) {
                    cursor.getLong(modifiedIndex)
                } else {
                    0L
                }
                entries.add(name to modified)
            }
        }
        entries.sortByDescending { it.second }
        return entries
    }

    /** 只保留最近 [keepCount] 份备份，返回删除数量。 */
    private fun pruneAutoBackups(treeUri: Uri, keepCount: Int): Int {
        if (keepCount <= 0) return 0
        val collection = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val stale = mutableListOf<String>()
        contentResolver.query(
            collection,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            )
            val nameIndex = cursor.getColumnIndex(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )
            val modifiedIndex = cursor.getColumnIndex(
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            )
            val rows = mutableListOf<Triple<String, String, Long>>()
            while (cursor.moveToNext()) {
                val id = if (idIndex >= 0) cursor.getString(idIndex) else null
                val name = if (nameIndex >= 0) cursor.getString(nameIndex) else null
                if (id == null || name == null || !isBackupFileName(name)) continue
                val modified = if (modifiedIndex >= 0) {
                    cursor.getLong(modifiedIndex)
                } else {
                    0L
                }
                rows.add(Triple(id, name, modified))
            }
            rows.sortByDescending { it.third }
            for (row in rows.drop(keepCount)) {
                stale.add(row.first)
            }
        }
        var deleted = 0
        for (documentId in stale) {
            try {
                val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                    treeUri,
                    documentId,
                )
                if (DocumentsContract.deleteDocument(contentResolver, documentUri)) {
                    deleted++
                }
            } catch (_: Exception) {
                // 单个文件删除失败不影响本次备份结果。
            }
        }
        return deleted
    }

    private fun isBackupFileName(name: String): Boolean =
        name.startsWith(BACKUP_FILE_PREFIX) && name.endsWith(".json", true)

    private fun hasPendingFileOperation(): Boolean =
        pendingContentPackResult != null ||
            pendingBackupOpenResult != null ||
            pendingBackupCreateResult != null ||
            pendingBackupFolderResult != null

    private fun safeBackupName(raw: String?): String {
        val cleaned = raw
            ?.replace(Regex("[^A-Za-z0-9._-]"), "_")
            ?.trim('_')
            ?.take(80)
            .orEmpty()
        val fallback = cleaned.ifBlank { "code_learn_backup" }
        return if (fallback.endsWith(".json", ignoreCase = true)) {
            fallback
        } else {
            "$fallback.json"
        }
    }

    @Deprecated("Uses the compatibility activity result callback for FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            CONTENT_PACK_REQUEST -> handleContentPackResult(resultCode, data)
            BACKUP_OPEN_REQUEST -> handleBackupOpenResult(resultCode, data)
            BACKUP_CREATE_REQUEST -> handleBackupCreateResult(resultCode, data)
            BACKUP_FOLDER_REQUEST -> handleBackupFolderResult(resultCode, data)
        }
    }

    private fun handleBackupFolderResult(resultCode: Int, data: Intent?) {
        val result = pendingBackupFolderResult ?: return
        pendingBackupFolderResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            // 取得长期授权，重启 App 后仍可继续写入该目录。
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            backupPrefs.edit().putString(BACKUP_TREE_KEY, uri.toString()).apply()
            result.success(uri.toString())
        } catch (error: Exception) {
            result.error(
                "folder_permission_failed",
                error.message ?: "persist permission failed",
                null,
            )
        }
    }

    private fun handleContentPackResult(resultCode: Int, data: Intent?) {
        val result = pendingContentPackResult ?: return
        pendingContentPackResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }
        try {
            val text = readUriText(data.data!!, MAX_CONTENT_PACK_BYTES)
            result.success(text)
        } catch (error: Exception) {
            if (error.message?.contains("too_large") == true) {
                result.error("pack_too_large", "Content pack exceeds 8 MB", null)
            } else {
                result.error("read_failed", error.message ?: "read failed", null)
            }
        }
    }

    private fun handleBackupOpenResult(resultCode: Int, data: Intent?) {
        val result = pendingBackupOpenResult ?: return
        pendingBackupOpenResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }
        try {
            result.success(readUriText(data.data!!, MAX_BACKUP_BYTES))
        } catch (error: Exception) {
            if (error.message?.contains("too_large") == true) {
                result.error("backup_too_large", "Backup exceeds 16 MB", null)
            } else {
                result.error("read_failed", error.message ?: "read failed", null)
            }
        }
    }

    private fun handleBackupCreateResult(resultCode: Int, data: Intent?) {
        val result = pendingBackupCreateResult ?: return
        val payload = pendingBackupPayload
        pendingBackupCreateResult = null
        pendingBackupPayload = null
        if (resultCode != Activity.RESULT_OK || data?.data == null || payload == null) {
            result.success(false)
            return
        }
        try {
            contentResolver.openOutputStream(data.data!!, "wt")?.use { stream ->
                stream.write(payload.toByteArray(Charsets.UTF_8))
            } ?: throw IllegalArgumentException("empty content URI")
            result.success(true)
        } catch (error: Exception) {
            result.error("write_failed", error.message ?: "write failed", null)
        }
    }

    private fun readUriText(uri: Uri, maxBytes: Int): String {
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw IllegalArgumentException("empty content URI")
        if (bytes.size > maxBytes) throw IllegalArgumentException("too_large")
        return String(bytes, Charsets.UTF_8)
    }

    override fun onDestroy() {
        destroySandbox()
        stopText()
        textToSpeech?.shutdown()
        textToSpeech = null
        ttsReady = false
        ttsChannel = null
        pendingContentPackResult?.error("activity_destroyed", "Activity destroyed", null)
        pendingContentPackResult = null
        pendingBackupOpenResult?.error("activity_destroyed", "Activity destroyed", null)
        pendingBackupOpenResult = null
        pendingBackupCreateResult?.error("activity_destroyed", "Activity destroyed", null)
        pendingBackupCreateResult = null
        pendingBackupFolderResult?.error("activity_destroyed", "Activity destroyed", null)
        pendingBackupFolderResult = null
        pendingBackupPayload = null
        super.onDestroy()
    }

    /** 在后台线程拼接并写出页面（Python 运行时有好几 MB，避免卡住主线程）。 */
    private fun runCode(language: String, code: String, result: MethodChannel.Result) {
        Thread {
            var page: File? = null
            var errorText: String? = null
            try {
                page = writeSandboxPage(language, code)
            } catch (error: Exception) {
                errorText = error.message ?: error.toString()
            }
            val pageFile = page
            val failure = errorText
            Handler(Looper.getMainLooper()).post {
                if (pageFile == null) {
                    result.success("执行失败：沙箱资源加载出错（$failure）。")
                } else {
                    showSandbox(pageFile, result)
                }
            }
        }.start()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun showSandbox(page: File, result: MethodChannel.Result) {
        destroySandbox()
        val session = SandboxSession(result)
        val bridge = ConsoleBridge(session)
        val webView = WebView(this)
        activeWebView = webView
        activePageFile = page
        with(webView.settings) {
            javaScriptEnabled = true
            // 沙箱不联网：脚本全部内联，网络加载一律禁止。
            blockNetworkLoads = true
            // 需要读取自己写出的沙箱页面，但不允许页面通过 file:// 读取别的文件。
            allowFileAccess = true
            allowFileAccessFromFileURLs = false
            allowUniversalAccessFromFileURLs = false
            allowContentAccess = false
            domStorageEnabled = false
            setSupportZoom(false)
            builtInZoomControls = false
            cacheMode = WebSettings.LOAD_NO_CACHE
        }
        webView.isVerticalScrollBarEnabled = false
        webView.isHorizontalScrollBarEnabled = false
        webView.addJavascriptInterface(bridge, "SandboxBridge")
        webView.webViewClient = WebViewClient()

        activeTimeout = Runnable {
            session.complete("执行超时：请检查是否有死循环、未结束的异步任务或过大的输入。")
        }.also {
            Handler(Looper.getMainLooper()).postDelayed(it, SANDBOX_TIMEOUT_MS)
        }

        webView.loadUrl(Uri.fromFile(page).toString())
    }

    /** 生成沙箱页面并写入缓存目录，返回文件句柄。 */
    private fun writeSandboxPage(language: String, code: String): File {
        val dir = File(cacheDir, SANDBOX_DIR).apply { mkdirs() }
        val page = File(dir, "$language.html")
        page.writeText(buildSandboxHtml(language, code), Charsets.UTF_8)
        return page
    }

    private fun buildSandboxHtml(language: String, code: String): String {
        val spec = specs[language] ?: specs.getValue("javascript")
        var html = readSandboxAsset("harness/${spec.harness}")
        spec.runtimes.forEachIndexed { index, path ->
            val marker = "/*__RUNTIME_${index + 1}__*/"
            html = html.replace(marker, escapeInlineScript(readSandboxAsset(path)))
        }
        html = html.replace(
            "/*__COMMON__*/",
            escapeInlineScript(readSandboxAsset("harness/common.js")),
        )
        // 用户代码最后替换，避免代码里出现同样的标记时被误替换。
        return html.replace("__USER_CODE__", encodeJsString(code))
    }

    private fun readSandboxAsset(relative: String): String = synchronized(assetCache) {
        assetCache.getOrPut(relative) {
            assets.open("flutter_assets/assets/sandbox/$relative")
                .bufferedReader(Charsets.UTF_8)
                .use { it.readText() }
        }
    }

    /** 内联脚本里出现 </script 会提前结束标签，转义后 JS 语义不变。 */
    private fun escapeInlineScript(source: String): String =
        source.replace("</script", "<\\/script")

    /** 把用户代码转成安全的 JS 字符串字面量。 */
    private fun encodeJsString(code: String): String = JSONObject.quote(code)
        .replace("</script", "<\\/script")
        .replace("\u2028", "\\u2028")
        .replace("\u2029", "\\u2029")

    private fun destroySandbox() {
        activeTimeout?.let { Handler(Looper.getMainLooper()).removeCallbacks(it) }
        activeTimeout = null
        activeWebView?.let { webView ->
            webView.removeJavascriptInterface("SandboxBridge")
            webView.stopLoading()
            webView.destroy()
        }
        activeWebView = null
        activePageFile?.delete()
        activePageFile = null
    }

    /** 一次执行会话：保证结果只回传一次，并在回传后清理 WebView。 */
    private inner class SandboxSession(private val result: MethodChannel.Result) {
        private val lock = Any()
        private var finished = false

        fun complete(output: String) {
            synchronized(lock) {
                if (finished) return
                finished = true
            }
            Handler(Looper.getMainLooper()).post {
                destroySandbox()
                result.success(output)
            }
        }
    }

    private inner class ConsoleBridge(private val session: SandboxSession) {
        @JavascriptInterface
        fun onResult(value: String) {
            session.complete(value)
        }
    }

    /** 使用随机 salt + AES-256-GCM 生成可移植的加密备份信封。 */
    private fun encryptBackup(plainText: String, password: String): String {
        val salt = ByteArray(SALT_BYTES)
        val iv = ByteArray(IV_BYTES)
        SecureRandom().nextBytes(salt)
        SecureRandom().nextBytes(iv)

        val kdfVersion = if (supportsSha256Kdf()) KDF_SHA256 else KDF_SHA1
        val key = deriveBackupKey(password, salt, kdfVersion)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.ENCRYPT_MODE,
            SecretKeySpec(key, "AES"),
            GCMParameterSpec(GCM_TAG_BITS, iv),
        )
        val encrypted = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
        val payload = ByteArray(1 + salt.size + iv.size + encrypted.size)
        payload[0] = kdfVersion
        System.arraycopy(salt, 0, payload, 1, salt.size)
        System.arraycopy(iv, 0, payload, 1 + salt.size, iv.size)
        System.arraycopy(
            encrypted,
            0,
            payload,
            1 + salt.size + iv.size,
            encrypted.size,
        )

        return ENVELOPE_PREFIX + Base64.encodeToString(payload, Base64.NO_WRAP)
    }

    /** 解密备份；密码错误时 GCM 认证会直接失败，不会返回半截明文。 */
    private fun decryptBackup(payloadString: String, password: String): String {
        val encoded = payloadString.trim().removePrefix(ENVELOPE_PREFIX)
        val payload = Base64.decode(encoded, Base64.DEFAULT)
        if (payload.size <= 1 + SALT_BYTES + IV_BYTES) {
            throw IllegalArgumentException("备份内容不完整")
        }

        val kdfVersion = payload[0]
        val salt = payload.copyOfRange(1, 1 + SALT_BYTES)
        val iv = payload.copyOfRange(1 + SALT_BYTES, 1 + SALT_BYTES + IV_BYTES)
        val encrypted = payload.copyOfRange(
            1 + SALT_BYTES + IV_BYTES,
            payload.size,
        )
        val key = deriveBackupKey(password, salt, kdfVersion)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            SecretKeySpec(key, "AES"),
            GCMParameterSpec(GCM_TAG_BITS, iv),
        )
        return String(cipher.doFinal(encrypted), Charsets.UTF_8)
    }

    /** Android 7 及以下没有 PBKDF2WithHmacSHA256，需要记录实际使用的算法。 */
    private fun supportsSha256Kdf(): Boolean = try {
        SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        true
    } catch (_: NoSuchAlgorithmException) {
        false
    }

    private fun deriveBackupKey(
        password: String,
        salt: ByteArray,
        kdfVersion: Byte,
    ): ByteArray {
        val algorithm = when (kdfVersion) {
            KDF_SHA256 -> "PBKDF2WithHmacSHA256"
            KDF_SHA1 -> "PBKDF2WithHmacSHA1"
            else -> throw IllegalArgumentException("不支持的备份加密版本")
        }
        val factory = SecretKeyFactory.getInstance(algorithm)
        val spec = PBEKeySpec(
            password.toCharArray(),
            salt,
            PBKDF2_ITERATIONS,
            KEY_BITS,
        )
        return factory.generateSecret(spec).encoded
    }

    private companion object {
        const val SANDBOX_DIR = "sandbox"
        const val ENVELOPE_PREFIX = "CLB1:"
        const val KDF_SHA256: Byte = 1
        const val KDF_SHA1: Byte = 2
        const val SALT_BYTES = 16
        const val IV_BYTES = 12
        const val KEY_BITS = 256
        const val GCM_TAG_BITS = 128
        const val PBKDF2_ITERATIONS = 120_000
        // 比 Dart 侧最长的超时（Python / SQL 30 秒）再多 2 秒，
        // 让正常流程由 Dart 侧给出统一提示，这里是最后的兜底。
        const val SANDBOX_TIMEOUT_MS = 32_000L
        const val CONTENT_PACK_REQUEST = 4201
        const val BACKUP_OPEN_REQUEST = 4301
        const val BACKUP_CREATE_REQUEST = 4302
        const val BACKUP_FOLDER_REQUEST = 4303
        const val BACKUP_TREE_KEY = "auto_backup_tree_uri"
        const val BACKUP_FILE_PREFIX = "code_learn_backup_"
        const val DEFAULT_BACKUP_KEEP = 5
        const val MAX_CONTENT_PACK_BYTES = 8 * 1024 * 1024
        // 单次分享的文本上限（256 KB），超过则退回复制到剪贴板。
        const val MAX_SHARE_TEXT_BYTES = 256 * 1024
        const val MAX_BACKUP_BYTES = 16 * 1024 * 1024
        const val BACKUP_SHARE_DIR = "backup_share"
    }
}
