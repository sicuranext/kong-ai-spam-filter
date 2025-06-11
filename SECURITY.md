# Security Policy

## Supported Versions

We currently support the latest stable release of the Kong AI Spam Filter plugin. Previous versions may not receive security updates.

## Reporting a Vulnerability

If you discover a security issue, potential bypass, or any behaviour that compromises the integrity of the plugin, please email `security@sicuranext.com` with a detailed description of the problem.

Please include the steps to reproduce the issue and any relevant logs or screenshots. We aim to respond within **72 hours**.

## Scope of the Project

This plugin was created primarily to test and demonstrate prompt injection and prompt hijacking techniques. As noted in the [README](README.md), there are countless ways to bypass the system prompts and guardrails embedded in the current implementation.

We welcome reports of these bypasses, but be aware that some may stem from the design goal of exploring LLM vulnerabilities.

For further background, see our blog post: [Influencing LLM Output using logprobs and Token Distribution](https://blog.sicuranext.com/infuencing-llm-output-using-logprobs-and-token-distribution/).

## Non-Security Issues

For general bug reports or feature requests, please open an issue in the repository rather than emailing the security address.

## Responsible Disclosure

We request that you give us a reasonable time to investigate and mitigate any reported issues before disclosing them publicly. We will credit researchers who help improve the security of this project in the README, unless you prefer to remain anonymous.

