# TCP/IP Stadium

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- I can explain in my own words what the TCP/IP Stadium solves, not just a word.
- The relationship between "TCP", "UDP," "IP" and "three handshakes" is clear, with one example.
- It's a way to put this subject back into the "network" of knowledge, and it shows that there are boundaries between them.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: Layer model, three handshakes and TCP/UDP trade-offs.

## Pre-knowledge

- The first lesson is the HTTP Foundation; if available, this course can be used for self-testing.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Review before starting: TCP, UDP, IP.
- If you can't read it at a certain step, record the specific card points and then go back to them.


I'm sorry.

## Layer Model

Network communications are broken down into layers, each of which is concerned with its own responsibilities:

|Layer|Typical protocol.|Problems|
| --- | --- | --- |
|Application Layer| HTTP、DNS、SMTP |Operational data formats|
|Transfer Layer| TCP、UDP |End to Port|
|Network Level| IP、ICMP |Address and route|
|Chain level| Ethernet、Wi-Fi |Contiguous device transfer|

When sent, the data will be sealed from top to bottom and received from bottom up:

```text
[以太网头][IP 头][TCP 头][HTTP 数据][以太网尾]
```

## IP: Responsible for location

IP address identifies a host, with routers and switches transmitting data packages to their destination under the head of IP. The IP protocol** does not guarantee reliability.** The package may be lost, disordered or duplicated.

```text
本机地址示例：192.168.1.10
公网地址示例：203.0.113.7
```

## TCP: Responsible for reliability

TCP achieves reliable transmission on unreliable IP, main mechanism:

1. ** Three handshakes.
2. ** Serial number + confirmed response ** Promised that it will not be lost, heavy and orderly.
3. ** Overtime.
4. ** Slided windows** for traffic control.
5. ** Concussion controls** avoid crushing the network.

Three handshakes:

```text
客户端 --SYN(seq=x)-->        服务器
客户端 <--SYN+ACK(seq=y,ack=x+1)-- 服务器
客户端 --ACK(ack=y+1)-->      服务器
```

Four wavers to release the connection, because TCP is full-time and both directions are closed.

## TCP versus UDP

|Features| TCP | UDP |
| --- | --- | --- |
|Connection|Face to Connection|No connection|
|Reliability|It's reliable and orderly.|I don't know.|
|Cost|Big.|Very small.|
|Typical scene.|Web page, file transfer|Live, Play, DNS|

## Port

Port used to distinguish between different services on the same host:

```text
HTTP   80
HTTPS  443
SSH    22
MySQL  3306
```

## Pick up the package.

|Fields|Meaning|Anomalous signal.|
| --- | --- | --- |
| Seq / Ack |Serial number and confirmation.|Serial number repeats.|
| Flags | SYN/ACK/FIN/RST/PSH |RST connection denied or forced to close|
| Window |Receiving Window Size|Close to zero. The receiver can't handle it.|
| MSS |Maximum session length|When you shake your hand, it'll affect the section.|
| TTL |Lifetime|It can be used to determine whether or not the system has been rewritten.|
| Retransmission |Rewrite Tags|High indicator of loss or chain vibrating|

## Common malfunctions and corresponding performance

|phenomena|Packaging Features|Check the direction.|
| --- | --- | --- |
|Unconnected (port open)|SYN, copy.|Service not activated, firewall denied|
|Connection timed out|Repeatedly SYN No Response|It's not working. We got dumped by the security team.|
|The transmission's slow.|Heavy Rewrite + Zero|Poor chain quality, slow intake|
|Connections Reset|Out of the blue.|Interception, application crash. Overtime.|
|Only big ones fail.|Part Lost, Path MTU Problem|MTU, adjust the path.|

If you've got these two tables, the output of ⟦ will go from "intellectual characters."

## Four stages of containment.

|Phase|Behaviour|Trigger|
| --- | --- | --- |
|Slow Start|Cwnd Thrust window doubles per RTT starting with 1 MSS|Create or overwrite connections|
|Concussion avoid.|1 MSS per RTT (linear growth)|cwnd to slow start threshold ssthresh|
|Quick Replay|3 repeats. ACK immediately retransmitted the lost message, not over time.|I don't know.|
|Quick Recovery|ssthresh halved, cwnd starts linearly from the new threshold|Quick re-enactment|

Overtime is much more costly than overtime:** Timeout will hit back 1 and quick recovery only halves the window. That's why occasional drop-off has a huge difference with time outage effects.

## Different crowd control algorithms

|Algebra|Thinking.|Features|
| --- | --- | --- |
| Reno |I'll cut it in half.|It's a classic. Throw it in the chain.|
| CUBIC |Grow with Three Functions|Linux Default for High Bandwidth Distance|
| BBR |Actively detect bandwidth and RTT, not signaling the drop.|We need a new core on the downlink.|

Capture package interpretation: Repeated ACK in continuous sight of the same Seq indicates that a dump pack triggers rapid re-transmission; an interval at RTO level (over hundreds of milliseconds) is overtime;Absorption but delayed stabilization is usually limited by the window (inadequate build-up of bandwidth).

## It's the end of this class.
In summary:** which machine is to be delivered, TCP/UDP for which application, and TCP Additional Assurances.**

<!-- appendix:v1 -->

## TCP Status Check

|Status|Organisation|Meaning|
| --- | --- | --- |
| `LISTEN` |Service|Wait for the connection.|
| `SYN_SENT` |Client|SYN, wait for SYN+ACK|
| `SYN_RCVD` |Service|Copy SYN and reply, ACK|
| `ESTABLISHED` |Both sides|Connection established, passable|
| `FIN_WAIT_1` / `FIN_WAIT_2` |Active closure|Sent FIN, pending confirmation or closure|
| `CLOSE_WAIT` |Passive closure|FIN, wait for the app to call.|
| `LAST_ACK` |Passive closure|FIN, wait for the final ACK|
| `TIME_WAIT` |Active closure|2MSL, make sure they get the ACK.|
| `CLOSED` |Both sides|The connection is completely over.|

⟦Accumulation indicates that the connection is forgotten; ⟦1 too often comes from short connections and can be reused or adjusted for core parameters.

## Let's shake hands.

|Phase|Messages|Key information|
| --- | --- | --- |
|Three handshakes.| SYN |client's initial serial number|
|Three handshakes.| SYN + ACK |service seq=y,ck=x+1|
|Three handshakes.| ACK |Client ack = y+1, connect|
|Four wavers.| FIN |No more data sent by the initiative|
|Four wavers.| ACK |Passive side confirmed.|
|Four wavers.| FIN |Passive data, too.|
|Four waves.| ACK |Proponent confirmed, enter TIME_WAIT|

## Check your commands.

|Purpose|Command|Annotations|
| --- | --- | --- |
|Look at the connection statistics.| `ss -s` |Summary of types socket|
|Look at the TCP connection list| `ss -tanp` |⟦ Show process, read only TCP|
|Watch the listening port.| `ss -tlnp` |Check if the service's actually listening.|
|TIME_WAIT| `ss -tan \| awk '{print $1}' \| sort \| uniq -c` |To determine if short connections are too many|
|Look at the bag and repeat it.| `netstat -s \| grep -i retrans` |High rate of re-transmission indicates poor network quality|
|Take the bag and shake hands three times.| `tcpdump -i any port 8080 -w a.pcap` |Parsing with Wireshark|
|Connectivity and delay| `ping`、`mtr` |I can see every one of them.|
|Test port to reach.| `nc -zv host port` |Rapid verification of firewalls and wiretaps|

## Common Error Table

|phenomena|Common causes|Treatment|
| --- | --- | --- |
|Connection Failed, Zero|The service is not listening or the port is wrong|Confirm listening address and port.|
|The connection's stuck.|Firewalls and roads are out of reach.|Line up with 0 and 1|
|It's a big pile.|Code's not closed.|Check if it's ⟦1 and the connection pool is leaking|
|It's a big pile.|Frequent Short Connections|Enable long connections and connect pools, adjust kernel parameters as necessary|
|Requesting occasional overtime, re-transmitting.|Network vibrating or MTU not matching|Grab the bag for re-transmission, check MTU and middle equipment.|
|Service refuses when connecting in large numbers|It's too small.|Bigger backlog with one.|
|The delay is too low.|Enabled Nagle to mix with small packages|Interactive scenes are on.|
|Failed to upload big files|Intermediate breakup|Heart beats, break points.|

## Self-Detected List

- [ ] Can draw three handshakes and four wavers, with each step change.
- [ ] Know the reason for its existence, and the difference between it and ⟦1.
- [ ] The listening port, the connection status and the process are viewed with ⟦0.
- [ ] Checking for connections will confirm whether the service is listening or not.
- [ ] Know the trade-off with Nagle algorithms.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeating, experimenting and delivering around TCP, UDP, IP, each result being checked.

A true request or agreement is drawn to interact, then a delay or a package is injected and each layer of change is explained.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with TCP/IP?
2. Without it, what concrete consequences would there be?
3. What's it got to do with UDP?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Draws a message or time chart that indicates the address, protocol, state and possible point of failure for each jump.

Mission requests:

- The result must be checked, not just “I understand”.
- "TCP" and "UDP" are at least covered.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** TCP/IP Stack

**Summary:** Layering, three-way handshake, TCP vs UDP.

**Category:** Networking  
**Level:** Progress
**Key terms:**TCP, UDP, IP, three handshakes, ports, protocols

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable environment: tCP/IP, HTTP/2, HTTP/3 and modern network
- Source: Internal structured curriculum and engineering practices
- Related themes: TCP, UDP, IP, three handshakes, ports, protocol bars
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- minimal-code:v1 -->

## Minimum Runable Example

The following example is used to verify the minimum input, processing and output of a TCP/IP stack. Run as it stands and modify only one value:

```python
import socket

print(socket.gethostbyname("localhost"))
```

## Expected output

```text
127.0.0.1
```

## Validation Steps

1. Record the operating environment, commands and real output.
2. Change an input, write a forecast and run it.
3. Creates an error input, records the wrong information and fixes it.
4. Write back the lesson notes or test examples.

<!-- top50-rewrite:v1 -->

## Course-specific fine reading: TCP/IP

### I. KNOWLEDGE

- **Strategic model: network communications are broken down into layers and each level is concerned with its own duties:
- ** IP: Responsible for the location of an IP address that identifies a host, with routers and switches transmitting data packages to their destination on the basis of IP. The IP agreement** does not guarantee reliability: packages may be lost, disordered or duplicated.
- **TCP: Responsible for reliability**: TCP achieves reliable transmission on unreliable IP, main mechanism:
- **TCP versus UDP: understand its definition, input, output and failure.
- ** Port: used to distinguish services from the same host:
- **Scraper: understand its definition, input, output and failed borders.
- ** Common malfunctions and correspondence**: understanding its definition, input, output and failure boundaries.
- **Four phases of crowd control**: understanding its definition, input, output and failure.

### II. MECHANISMS AND VERIFICATION

|Theme|Questions to answer|Authentication Method|
| --- | --- | --- |
|Layer Model|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|IP: Responsible for location|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|TCP: Responsible for reliability|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|TCP versus UDP|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Port|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Pick up the package.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Common malfunctions and corresponding performance|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Four stages of containment.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|

### III. EXCHANGE ISSUES

1. What's the boundary between a layered model and an adjacent subject?
2. IP: What's the border with the adjacent subject?
3. TCP: What's the border between reliable and adjacent?
4. TCP against UDP. What's the border with adjacent themes?
5. What's the border with the adjacent subject?
6. What's the border with an adjacent theme?
7. What's the boundary between common failures and matching behavior?
8. What are the four stages of congested control with each other?

### IV. FUNCTIONS CLASSING

1. Fixed input and environment, confirming problem recurrence.
2. Find the first anomaly, don't guess from the end.
3. Only one variable is changed, and projections and real results are recorded.
4. Rehabilitate borders, fail and repeat tests.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**TCP/IP Stack** focuses on Layering, three-way handshake, TCP vs UDP.

### Learning Outcomes

- Explain what **TCP/IP Stack** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **TCP/IP Stack**
- Relaid terms: TCP, UDP, three handshakes
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Layer Model|Model|
|IP: Responsible for location|IP: Responsible for location|
|TCP: Responsible for reliability|TCP: Responsible for reliability|
|TCP versus UDP|TCP versus UDP|
|Port|Port|
|Pick up the package.|Pick up the package.|
|Common malfunctions and corresponding performance|Common Failure and Correlation|
|Four stages of containment.|Four stages of containment.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

