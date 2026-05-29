# curbioc.py
# based on Anh Nguyet Vu github.com/anngvu/bioc-curation
# Vince Carey stripped out notebook components to expose functions for
# calling from R via reticulate

import re
import requests
import json
from jsonschema import validate, ValidationError
import pandas as pd

# LLM state – all set by init_client() before use
_provider = None
client = None
MODEL = None
loaded_reference = {}

_REFERENCE_URLS = {
    'topic':     'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_topics.json',
    'operation': 'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_operations.json',
    'data':      'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_data.json',
    'format':    'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_formats.json',
}


def _load_references():
    global loaded_reference
    for subset, url in _REFERENCE_URLS.items():
        resp = json.loads(requests.get(url).text)
        terms = next(iter(resp.values()))
        loaded_reference[subset] = {item['lbl']: item['id'] for item in terms}


def init_client(api_key, provider="openai", model=None):
    """Initialize the LLM client, set MODEL, and load EDAM reference tables.

    Must be called before schema_completion or fix_completion.
    Supported providers: 'openai', 'anthropic', 'gemini'.
    """
    global client, MODEL, _provider
    MODEL = model
    _provider = provider
    if not loaded_reference:
        _load_references()
    if provider == "openai":
        import openai as _openai
        client = _openai.OpenAI(api_key=api_key)
    elif provider == "anthropic":
        import anthropic as _anthropic
        client = _anthropic.Anthropic(api_key=api_key)
    elif provider == "gemini":
        from google import genai as _genai
        client = _genai.Client(api_key=api_key)
    else:
        raise ValueError(
            f"Unsupported provider: '{provider}'. Supported: openai, anthropic, gemini"
        )


def _complete(system, user):
    """Call the active LLM provider and return the response text."""
    if client is None or MODEL is None:
        raise RuntimeError("Call init_client() before using LLM functions.")
    if _provider == "openai":
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": system},
                {"role": "user",   "content": user},
            ],
        )
        return resp.choices[0].message.content
    elif _provider == "anthropic":
        resp = client.messages.create(
            model=MODEL,
            max_tokens=4096,
            system=system,
            messages=[{"role": "user", "content": user}],
        )
        return resp.content[0].text
    elif _provider == "gemini":
        from google.genai import types as _types
        resp = client.models.generate_content(
            model=MODEL,
            contents=user,
            config=_types.GenerateContentConfig(system_instruction=system),
        )
        return resp.text
    else:
        raise RuntimeError(f"Unknown provider '{_provider}' – was init_client() called?")


def _extract_json(text):
    """Strip markdown code fences that LLMs sometimes add despite instructions."""
    text = text.strip()
    text = re.sub(r'^```[a-zA-Z]*\n?', '', text)
    text = re.sub(r'\n?```\s*$', '', text)
    return text.strip()


def get_text_from_url(url, trim=False):
    try:
        response = requests.get(url)
        response.raise_for_status()
        tmp = response.text
        if (len(tmp) > 30000) and trim:
            tmp = tmp[0:30000:1]
        return tmp
    except requests.exceptions.RequestException as e:
        print(f"Error fetching URL: {e}")
        return None


def schema_completion(content, schema, temp=0.0):
    system = (
        "You are a helpful expert in data curation and data modeling, especially with structured JSON data."
        "You return only valid JSON string, not in a code block, and without any other explanation so that the string can be decoded and inserted into a database."
    )
    user = (
        "Given content about a bioinformatics tool, represent it as a JSON object compliant with the provided schema:"
        "\nCONTENT:\n\n" + content + '\nSCHEMA:\n\n' + schema
    )
    return _extract_json(_complete(system, user))


def fix_completion(content, error):
    system = "You are debugging an API. Review the given JSON object and schema error and return the corrected JSON object only. Do not use code blocks."
    user = "JSON:\n\n" + content + "\nSchema ERROR:\n\n" + error
    return _extract_json(_complete(system, user))


def validate_json_with_retries(json_string, schema, max_retries=3, attempts=0):
    if attempts > max_retries:
        raise Exception(f"Failed to validate JSON after {max_retries} attempts")
    try:
        parsed_json = json.loads(json_string)
        validate(instance=parsed_json, schema=schema)
        print("Success after", attempts, "attempts")
        return parsed_json
    except (json.JSONDecodeError, ValidationError) as e:
        attempts += 1
        print("JSON not valid, trying QC/correction prompt, attempt", attempts)
        if attempts == max_retries:
            raise
        json_string = fix_completion(json_string, str(e))
        return validate_json_with_retries(json_string, schema, max_retries, attempts)


# https://openai.com/api/pricing/ — OpenAI provider only
def openai_completion_cost(usage):
    input_pricing_per_token = 0.0000025
    output_pricing_per_token = 0.00001
    return (usage.prompt_tokens * input_pricing_per_token) + (usage.completion_tokens * output_pricing_per_token)


def transform_with_uri(terms, subset):
    return [{"term": term["term"], "uri": loaded_reference[subset][term.get("term")]} for term in terms]


def transform_terms(data):
    new_data = {}
    if isinstance(data, dict):
        for key, value in data.items():
            if key in ("operation", "topic", "format"):
                new_data[key] = [{"term": term["term"], "uri": loaded_reference[key][term.get("term")]} for term in value]
            elif key == "data":
                new_data[key] = {"term": value["term"], "uri": loaded_reference[key][value["term"]]}
            else:
                new_data[key] = transform_terms(value)
        return new_data
    elif isinstance(data, list):
        return [transform_terms(item) for item in data]
    else:
        return data


def final_validation(merged):
    try:
        validate(merged, biotools_original_validation)
        return ""
    except Exception as e:
        return str(e)
