# AI Tools & Models Disclosure

> **Samsung Gen AI Hackathon 3.0 — Theme 05: Interruptible Real-Time Agents** <br>
> **Submitted by:** Team MSRIT_Cache_Me <br>
> **Repository:** https://github.com/AnanthAkshay/Samsung_Gen_AI <br>
> **Disclosure Prepared:** 30-09-2026

---

# 1. Team Details

| Field                          | Details                                   |
| :----------------------------- | :---------------------------------------- |
| **Team Name**                  | Cache_Me / Samsung_Gen_AI_Hackathon_3.0   |
| **Project / Product Name**     | Full-Bench-Duplex                         |
| **Theme**                      | Theme 05 — Interruptible Real-Time Agents |
| **Organization / Institution** | M S Ramaiah Institute of Technology (MSRIT)|
| **Submission Date**            | 30-09-2026                                |

---

# 2. AI Usage Declaration

**Did your team use any Artificial Intelligence (AI) in developing this project?**

**Yes.**

AI was used both as part of the submitted system and as a development-assistance tool. The primary submitted agent uses **Gemini 2.5 Flash Native Audio** through the Gemini Live API. Additional AI tools were used during development for code review, debugging, documentation, and API/integration research.

---

# 3. Purpose of AI Usage

| Purpose                             |     Used?    | Details                                                                                                       |
| :---------------------------------- | :----------: | :------------------------------------------------------------------------------------------------------------ |
| **Idea generation / brainstorming** |      Yes     | AI-assisted discussion and exploration of implementation approaches during development.                       |
| **Code generation or assistance**   |      Yes     | Claude was used interactively for code review, debugging assistance, and development support.                 |
| **UI / UX design**                  | No / Limited | No AI-generated UI was used as a core component of the submitted system.                                      |
| **Content creation**                |      Yes     | AI assistance was used for technical documentation, README content, and project documentation.                |
| **Data analysis**                   |      Yes     | AI-assisted development and review of benchmark/evaluation workflows.                                         |
| **Testing / debugging**             |      Yes     | Claude assisted with debugging the benchmark harness, evaluation scripts, and reproduction workflows.         |
| **Other**                           |      Yes     | Gemini was used to verify Gemini Live API usage patterns and `livekit-plugins-google` integration approaches. |

---

# 4. Feature Origin Classification

## Feature 1 — Real-Time Voice Agent

**Feature Name:** Real-Time Voice Agent

**Origin:** Both — Self-Generated + AI-Assisted

**Description:**

* **AI Tool / Platform Used:** Gemini 2.5 Flash Native Audio through the Gemini Live API.
* **Role:** Primary AI model in the submitted system.
* **Purpose:** Handles speech understanding, intent detection, function calling, and audio response synthesis end-to-end.
* **Prompt Used:** The agent system prompt in `lk_agent_tool.py` (`VoiceAgent.instructions`) was authored and reviewed by the team.
* **Output Summary:** Real-time conversational audio responses and tool/function calls based on user input.
* **Modification:** The team designed the agent behavior, system instructions, tool definitions, and integration logic. AI-generated model output is used at runtime as part of the submitted system.

---

## Feature 2 — Interruptible Agent Interaction

**Feature Name:** Interruptible Real-Time Agent Interaction

**Origin:** Both — Self-Generated + AI-Assisted

**Description:**

* **AI Tool / Platform Used:** Gemini 2.5 Flash Native Audio / Gemini Live API.
* **Role:** Provides the real-time conversational intelligence required for interactive voice-agent behavior.
* **Prompt Used:** Human-authored system instructions defining the expected agent behavior.
* **Output Summary:** The model processes live conversational input and produces corresponding responses while supporting the application's real-time interaction flow.
* **Modification:** The team implemented and integrated the real-time agent infrastructure, tool handling, interruption flow, and surrounding application logic.

---

## Feature 3 — Tool / Function Calling

**Feature Name:** Agent Tool Calling

**Origin:** Both — Self-Generated + AI-Assisted

**Description:**

* **AI Tool / Platform Used:** Gemini 2.5 Flash Native Audio through Gemini Live API.
* **Role:** Detects when an available function/tool should be invoked and produces the required function-call information.
* **Prompt Used:** Tool behavior and descriptions were defined by the team within the application.
* **Output Summary:** Structured tool/function calls generated by the agent based on conversational context.
* **Modification:** Tool definitions, application-side execution, argument handling, and integration were implemented and reviewed by the team.
* **Additional Clarification:** No benchmark scenario IDs, dialogue text, or expected answers are hardcoded into the tool definitions.

---

## Feature 4 — Benchmark ASR Pipeline

**Feature Name:** Audio Transcription for Benchmark Evaluation

**Origin:** Both — Self-Generated + AI-Assisted

**Description:**

* **AI Tool / Platform Used:** NVIDIA Parakeet TDT 0.6B v2 via HuggingFace.
* **Role:** Benchmark-only automatic speech recognition (ASR).
* **Prompt Used:** Not applicable; the model is used for automatic speech transcription.
* **Output Summary:** Transcriptions of input and output audio used for latency measurement and tool-call extraction during evaluation.
* **Modification:** Integrated into `run_tool_benchmark_all_released.py` as part of the evaluation pipeline.
* **Important Clarification:** Parakeet is **not used during agent inference** and is not part of the submitted agent's runtime model stack.

---

## Feature 5 — Benchmark Evaluation

**Feature Name:** Tool-Call and Pass-Rate Evaluation

**Origin:** Self-Generated, AI-Assisted Development

**Description:**

* **AI Tools Used During Development:** Claude (Sonnet / Opus).
* **Role:** Assisted with code review, debugging, and refinement of the benchmark/evaluation harness.
* **Prompt Used:** Interactive development and debugging prompts concerning evaluation scripts and benchmark workflows.
* **Output Summary:** Suggestions, debugging assistance, and documentation/reproduction support.
* **Modification:** All evaluation logic and final benchmark scripts were reviewed and integrated by the team.
* **Evaluation Method:** Reported F1, pass rate, and latency metrics use exact-match evaluation.
* **Clarification:** GPT-4o was **not used for the reported benchmark results**.

---

## Feature 6 — Optional LLM Evaluation Judge

**Feature Name:** Optional Response-Quality Judge

**Origin:** AI-Assisted / Optional

**Description:**

* **AI Tool / Platform Used:** GPT-4o.
* **Provider:** OpenAI.
* **Role:** Optional LLM judge available through the `--use-llm` option in `evaluate_tool_calls.py` and `evaluate_pass_rate.py`.
* **Output Summary:** Can provide a `response_qual` score for response-quality evaluation.
* **Modification:** Integrated as an optional evaluation path.
* **Important Clarification:** GPT-4o was **not used in the submitted agent** and **was not used for any reported benchmark results**. Reported metrics were generated without an OpenAI API key using exact-match evaluation.

---

## Feature 7 — Development Assistance

**Feature Name:** Code Review, Debugging and Documentation Assistance

**Origin:** Both — Human Development + AI Assistance

**Description:**

* **AI Tool / Platform Used:** Claude (Sonnet / Opus) via Antigravity IDE.
* **Provider:** Anthropic.
* **Purpose:** Code review, debugging, benchmark-harness development, reproduction-script drafting, and technical documentation.
* **Prompt Used:** Interactive development prompts relating to code review, debugging, benchmark execution, documentation, and reproduction workflows.
* **Output Summary:** Suggestions, explanations, debugging assistance, code/documentation drafts, and review feedback.
* **Modification:** Team members reviewed, modified, tested, and integrated the resulting suggestions.
* **Clarification:** Claude did not autonomously generate the benchmark-facing agent prompts or tool definitions. Final implementation decisions were made by human team members.

---

## Feature 8 — API and Integration Research

**Feature Name:** Gemini Live API / LiveKit Integration

**Origin:** Both — Human Research + AI-Assisted Research

**Description:**

* **AI Tool / Platform Used:** Gemini Chat / Google AI Studio.
* **Provider:** Google.
* **Purpose:** Checking Gemini Live API usage patterns and `livekit-plugins-google` integration approaches.
* **Output Summary:** Technical guidance and examples related to API usage and integration.
* **Modification:** The team independently implemented and adapted the integration for the project.

---

# 5. AI Models Used in the Submitted System

| Tool / Model                                                                        | Provider             | Role in Submission                                                                                                                                                                      |
| :---------------------------------------------------------------------------------- | :------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Gemini 2.5 Flash Native Audio** (`gemini-2.5-flash-native-audio-preview-12-2025`) | Google DeepMind      | **Primary agent model.** Handles speech understanding, intent detection, function calling, and audio response synthesis through the Gemini Live API. This is the core evaluated system. |
| **NVIDIA Parakeet TDT 0.6B v2**                                                     | NVIDIA / HuggingFace | **Benchmark ASR only.** Used to transcribe input/output audio for latency measurement and tool-call extraction. It is not used during agent inference.                                  |

---

# 6. AI Models Used Optionally / Not in Primary Submitted Results

| Tool / Model | Provider | Role                                                                                                                                                  |
| :----------- | :------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GPT-4o**   | OpenAI   | Optional LLM judge for response-quality evaluation. Available through evaluation scripts but **not used in the reported results or submitted agent**. |

---

# 7. Development AI Tools

| Tool                        | Provider  | Usage                                                                                                             |
| :-------------------------- | :-------- | :---------------------------------------------------------------------------------------------------------------- |
| **Claude Sonnet / Opus**    | Anthropic | Code review, debugging, benchmark-harness assistance, reproduction-script drafting, and documentation assistance. |
| **Gemini Chat / AI Studio** | Google    | Research into Gemini Live API usage and `livekit-plugins-google` integration patterns.                            |

---

# 8. Clarifications on AI-Assisted Development

### 8.1 Human-Authored Agent Prompts

The agent prompts used in the submitted system were **written and reviewed by human team members**.

Claude was used to review and critique the prompts, but the final wording and behavioral decisions were made by the team.

### 8.2 No Fine-Tuning

No benchmark data was used to fine-tune any model.

The Gemini model is used **zero-shot**, without project-specific fine-tuning.

### 8.3 No Benchmark-Specific Hardcoding

No benchmark scenario IDs, dialogue text, or expected answers are hardcoded into the agent code or tool definitions.

`mock_apis.py` returns generic responses based on caller-provided arguments and does not contain a lookup table of benchmark-specific answers.

### 8.4 GPT-4o Clarification

OpenAI GPT-4o is present only as an optional evaluation path.

It was **not used as part of the submitted agent** and was **not used to generate the reported benchmark metrics**.

### 8.5 Human Review and Responsibility

All AI-assisted outputs used in the project were reviewed, modified, tested, and integrated by the development team.

The team retains responsibility for the final implementation, prompts, tool definitions, evaluation methodology, documentation, and submitted system.

### 8.6 Argument Formatting Failure Mode and Fix Attempt

The complete exact-match baseline exposed argument-value formatting errors: date strings were sometimes normalized to ISO-8601, spoken identifiers sometimes gained or lost punctuation, primitive number/boolean values were sometimes emitted as strings, and other argument values were incorrect. The 21 strict failures in this category break down into 7 date-format mismatches, 5 identifier-format mismatches, 4 number/boolean representation mismatches, and 7 other value mismatches.

A general prototype added tool-schema format guidance and schema-driven coercion for unambiguous boolean and numeric strings while preserving ordinary text and identifiers. It contained no benchmark-specific scenario IDs or expected values. The baseline subset had 2 correctly matched argument calls out of 25 (0.080 micro accuracy; 0.048 mean per-scenario argument accuracy). The replay produced only 1 turn-taken response out of 21; the other 20 were silent. Exact-match evaluation of that replay recorded 0.0 all-sample argument accuracy and 0/21 strict passes, with all-sample tool-selection F1 falling from 1.000 on the baseline subset to 0.048 on the replay. The worker also logged a 175.5-second event-loop stall.

Because the replay was dominated by silent outputs and a severe runtime stall, it does not establish that the prototype improved argument quality. The prototype was reverted, no full 100-scenario rerun was performed, and the reported full-run results remain the original exact-match baseline. Argument formatting and reliable subset evaluation remain limitations.

---

# 9. Ethical & Compliance Confirmation

* [x] **AI usage complies with applicable hackathon guidelines and policies.**
* [x] **No proprietary or copyrighted data was knowingly misused for AI development.**
* [x] **No benchmark data was used to fine-tune the submitted model.**
* [x] **AI-generated outputs used during development were reviewed by team members.**
* [x] **The submitted agent and benchmark-facing prompts/tool definitions were finalized by human team members.**

---

# 10. Declaration & Sign-Off

We hereby declare that the information provided in this AI Usage Disclosure is accurate to the best of our knowledge and represents the AI tools, models, and AI-assisted development practices used in developing the submitted project.

| Field                           | Details                        |
| :------------------------------ | :----------------------------- |
| **Name of Team Representative** | Akshay A |
| **Role**                        | Software Developer |
| **Signature**                   | Akshay A |
| **Date**                        | 30-09-2026 |

---

**Document:** `DISCLOSURE.md` <br>
**Disclosure Prepared:** 30-09-2026 <br>
**Project:** Full Bench Duplex — Samsung Gen AI Hackathon 3.0
