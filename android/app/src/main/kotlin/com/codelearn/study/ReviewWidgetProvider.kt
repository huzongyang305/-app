package com.codelearn.study

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * 桌面小组件「每日复习」。
 *
 * 数据只有一条单向通道：App 在前台时把到期题数、闪卡数、连续打卡天数、
 * 今日已学分钟与目标写进 shared_preferences 落盘的那个字符串
 * （键 flutter.widget_review_snapshot），小组件读取并渲染。
 * 小组件不查 Hive、不联网，进程被杀后依然能显示最后一次同步的结果。
 *
 * 刻意只用 RemoteViews + 系统控件实现，不引入 androidx.glance，
 * 避免为一个小部件把 APK 顶破商店的 95 MiB 体积线。
 */
class ReviewWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            refresh(context)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { render(context, appWidgetManager, it) }
    }

    companion object {
        /** App 侧主动请求刷新（系统自身的轮询最快也是 30 分钟一次）。 */
        const val ACTION_REFRESH = "com.codelearn.study.action.REFRESH_REVIEW_WIDGET"

        /** 点击小组件时随 Intent 带过去的跳转目标，与通知 payload 用同一套取值。 */
        const val EXTRA_ROUTE = "widget_route"
        const val ROUTE_REVIEW = "review"
        const val ROUTE_DAILY_QUESTION = "daily_question"

        // Flutter 的 shared_preferences 插件在 Android 侧落盘的文件名与键前缀。
        private const val PREFS_FILE = "FlutterSharedPreferences"
        private const val PREF_KEY = "flutter.widget_review_snapshot"
        private const val PAYLOAD_VERSION = "v1"
        private const val PAYLOAD_FIELDS = 7
        private const val ROOT_REQUEST_CODE = 1101
        private const val DAILY_REQUEST_CODE = 1102

        private data class Snapshot(
            val dueQuestions: Int,
            val dueFlashcards: Int,
            val streakDays: Int,
            val minutesToday: Int,
            val goalMinutes: Int,
        )

        /** 立即刷新桌面上所有本小组件实例。 */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ReviewWidgetProvider::class.java),
            )
            ids.forEach { render(context, manager, it) }
        }

        /**
         * 载荷格式 `v1|到期题|到期卡|连续天|今日分钟|目标分钟|时间戳`。
         *
         * 版本号与字段数都要核对：App 升级后格式变了，旧载荷应当退化成
         * 「打开 App 同步数据」，而不是把错位数字显示给用户。
         */
        private fun parse(raw: String?): Snapshot? {
            val parts = raw?.split('|') ?: return null
            if (parts.size != PAYLOAD_FIELDS || parts.first() != PAYLOAD_VERSION) return null
            val numbers = parts.drop(1).map { it.toLongOrNull() ?: return null }
            return Snapshot(
                dueQuestions = numbers[0].coerceAtLeast(0L).toInt(),
                dueFlashcards = numbers[1].coerceAtLeast(0L).toInt(),
                streakDays = numbers[2].coerceAtLeast(0L).toInt(),
                minutesToday = numbers[3].coerceAtLeast(0L).toInt(),
                goalMinutes = numbers[4].coerceAtLeast(1L).toInt(),
            )
        }

        private fun render(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val stored = context
                .getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                .getString(PREF_KEY, null)
            val snapshot = parse(stored)
            val views = RemoteViews(context.packageName, R.layout.widget_review)
            if (snapshot == null) {
                val hint = context.getString(R.string.widget_review_pending)
                views.setTextViewText(R.id.widget_streak, hint)
                views.setTextViewText(R.id.widget_goal_label, hint)
                views.setProgressBar(R.id.widget_goal_progress, 100, 0, false)
            } else {
                views.setTextViewText(R.id.widget_due_questions, snapshot.dueQuestions.toString())
                views.setTextViewText(R.id.widget_due_flashcards, snapshot.dueFlashcards.toString())
                views.setTextViewText(R.id.widget_minutes, snapshot.minutesToday.toString())
                views.setTextViewText(
                    R.id.widget_streak,
                    context.getString(R.string.widget_review_streak, snapshot.streakDays),
                )
                val goal = snapshot.goalMinutes
                val goalLabel = when {
                    snapshot.dueQuestions == 0 && snapshot.dueFlashcards == 0 ->
                        context.getString(R.string.widget_review_all_clear)
                    snapshot.minutesToday >= goal ->
                        context.getString(R.string.widget_review_goal_done)
                    else -> context.getString(
                        R.string.widget_review_goal,
                        snapshot.minutesToday,
                        goal,
                    )
                }
                views.setTextViewText(R.id.widget_goal_label, goalLabel)
                views.setProgressBar(
                    R.id.widget_goal_progress,
                    goal,
                    snapshot.minutesToday.coerceIn(0, goal),
                    false,
                )
            }
            views.setOnClickPendingIntent(
                R.id.widget_review_root,
                routeIntent(context, ROUTE_REVIEW, ROOT_REQUEST_CODE),
            )
            views.setOnClickPendingIntent(
                R.id.widget_daily_button,
                routeIntent(context, ROUTE_DAILY_QUESTION, DAILY_REQUEST_CODE),
            )
            manager.updateAppWidget(appWidgetId, views)
        }

        private fun routeIntent(context: Context, route: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra(EXTRA_ROUTE, route)
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                )
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
