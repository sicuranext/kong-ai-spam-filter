# Kong AI Spam Filter Plugin

## Overview
The Kong AI Spam Filter plugin uses advanced Large Language Models (LLMs) to detect and filter spam content in API requests and form submissions. It acts as an intelligent barrier that can identify various types of unwanted content while allowing legitimate requests to pass through.

## What It Does
This plugin intercepts incoming requests to your API or website forms and analyzes their content using AI models from leading providers:

- OpenAI (GPT-4o, GPT-4o-mini)
- Google (Gemini 2.0 Flash)
- Anthropic (Claude 3.7 Sonnet)
- Local models with ollama

When spam is detected, the plugin can either block the request entirely or log the incident, depending on your configuration.

## Why Use Kong AI Spam Filter?
Traditional spam filters rely on static rules, keywords, or basic pattern matching, which sophisticated spammers can easily bypass. This plugin leverages state-of-the-art language models to understand context, intent, and subtle indicators of spam that rule-based systems miss.

### Categorized Detection
The plugin doesn't just identify spam - it categorizes it by type:
- Advertising
- Phishing attempts
- Health-related spam
- Adult content
- Suspicious product offers
- Dating solicitations
- Scams
- Malware distribution attempts
- Other spam types

### Example default output
The plugin returns JSON responses that clearly indicate whether the analyzed content is spam, and if so, provides details about the type and reason:

For legitimate messages:
```json
{
  "is_spam": false
}
```

For spam messages:
```json
{
  "is_spam": true,
  "category": "advertising",
  "reason": "Message contains unsolicited promotional content for cryptocurrency investment"
}
```

### Flexible Configuration
- Choose which paths and content patterns to protect
- Select from multiple AI models based on your needs
- Configure response actions (block or log)
- Fine-tune the AI's behavior with temperature and token settings

### Configuring `request_path_regex` and `request_body_regex`
These parameters define which requests are inspected by the plugin. `request_path_regex` is an array of regular expressions matched against the request path, while `request_body_regex` is matched against the raw request body. The plugin only calls the LLM when at least one pattern from **both** arrays matches, preventing unnecessary requests and reducing cost and latency. For example, you can scan only contact form submissions that include a `message` field:

```json
"request_path_regex": ["^/contacts$"],
"request_body_regex": ["message=.+"]
```

### Reduced False Positives
The plugin is designed to recognize legitimate contact requests, support inquiries, and business communications while filtering out unwanted content.

## Use Cases
- Protect contact forms from spam submissions
- Filter API endpoints that accept user-generated content
- Shield comment sections and public-facing inputs
- Prevent abuse of messaging and communication features

By integrating AI capabilities into your Kong API gateway, this plugin provides sophisticated content filtering without requiring complex infrastructure or extensive development resources.

## ⚠️ Security Implications
While this plugin provides powerful spam detection capabilities, it should not be used as your sole protection mechanism. Due to the nature of LLM-based analysis:

1. **API Rate Limits & Costs**: Each request processed by this plugin makes an API call to an LLM provider, which:
   - Counts against your API rate limits
   - Incurs a financial cost per request
   - May be subject to throttling during high demand

2. **Recommended Protection Layers**:
   - **Rate Limiting**: Always deploy alongside Kong's rate limiting plugin to prevent abuse
   - **JavaScript Challenges**: For web forms, implement CAPTCHA or other JavaScript challenges before allowing form submission
   - **IP Blocking**: Consider adding IP blocking for repeated suspicious activity

3. **Cost Management**:
   - Configure path and body regex patterns carefully to only analyze relevant requests
  - Use *local* or the lightest model appropriate for your needs (e.g., gpt-4o-mini or gemini-2.0-flash vs gpt-4o)
   - Consider implementing a quota system at the application level

Without these additional protections, automated threats could rapidly exhaust your API quotas or generate unexpected costs through repeated requests.

## Testing with Docker

1. Make sure you have **Docker** and **Docker Compose** installed.
2. Start the environment:

   ```bash
   cd docker
   docker compose up -d
   ```

   Wait until Kong responds on `http://localhost:8001`.
3. Export the API keys used by the setup script:

   ```bash
   export GEMINI_API_KEY=your_gemini_key
   export OPENAI_API_KEY=your_openai_key
   export ANTHROPIC_API_KEY=your_anthropic_key
   ```

4. Configure Kong by running the setup file:

   ```bash
   hurl --variable GEMINI_API_KEY=$GEMINI_API_KEY \
        --variable OPENAI_API_KEY=$OPENAI_API_KEY \
        --variable ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
        tests/000_setup.hurl
   ```

5. Alternatively, you can configure Kong manually using `curl` commands.
   The following example creates a service, exposes it with a route and
   enables the plugin:

   ```bash
   # create an upstream service
   curl -X POST http://localhost:8001/services \
        -H "Content-Type: application/json" \
        -d '{"name":"example","url":"https://httpbin.org/anything"}'

   # create a route for the service
   curl -X POST http://localhost:8001/routes \
        -H "Content-Type: application/json" \
        -d '{"hosts":["example"],"service":{"name":"example"}}'

   # enable the plugin on the service
   curl -X POST http://localhost:8001/services/example/plugins \
        -H "Content-Type: application/json" \
        -d '{
             "name": "kong-ai-spam-filter",
             "config": {
               "api_key_google": "<GEMINI_API_KEY>",
               "api_key_openai": "<OPENAI_API_KEY>",
               "api_key_anthropic": "<ANTHROPIC_API_KEY>",
               "model": "gemini-2.0-flash",
               "request_path_regex": [".*"],
               "request_body_regex": [".*"]
             }
           }'
   ```

6. Execute the sample tests:

   ```bash
   hurl tests/003_spam_simple.hurl
   ```

   Or run an equivalent check using `curl`:

   ```bash
   # this message should be allowed
   curl -i -X POST http://localhost:8000/ \
        -H "Host: example" \
        -d "message=hello, I'm interested in your product. Please send me more information."

    # this request should be blocked with HTTP 403
    curl -i -X POST http://localhost:8000/ \
         -H "Host: example" \
         -d "message=hello, are you interested in training at low costs? Visit our website traninglowcost dot com."
   ```

7. When you are done, remove the configuration and stop the containers:

   ```bash
   hurl tests/999_shutdown.hurl  # clean up Kong objects
   docker compose down           # stop and remove containers
   ```
# TODO


## add here our tests about prompt injection/hijacking

## add here instructions to report security issue or bypasses
and related list of users who contributed

