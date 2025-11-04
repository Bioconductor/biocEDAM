# curbioc.py
# based on Anh Nguyet Vu github.com/anngvu/bioc-curation
# Vince Carey stripped out notebook components to expose functions for
# calling from R via reticulate

import requests
import openai
import os
import json
from jsonschema import validate, ValidationError

# new 7 nov
import pandas as pd
import tiktoken

embedding_model = "text-embedding-3-large"
embedding_encoding = "cl100k_base" # check
max_tokens = 8000

encoding = tiktoken.get_encoding(embedding_encoding)

# end new

OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
MODEL="%%MODEL%%"
client = openai.OpenAI(api_key=OPENAI_API_KEY)

# This segment prepares EDAM-oriented schemas

# EDAM data still needs post-AI processing to merge in class ids using a reference file before it is truly valid
references = {
    'topic' : 'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_topics.json',
    'operation' : 'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_operations.json',
    'data': 'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_data.json',
    'format': 'https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/subsets/edam_formats.json'
}

loaded_reference = {}

# Load each reference file into the dictionary
for subset, url in references.items():
    response = json.loads(requests.get(url).text)
    terms = next(iter(response.values()))
    loaded_reference[subset] = {item['lbl']: item['id'] for item in terms}

# end of schema reference processing

# Basic python functions from Anh:

def get_text_from_url(url, trim=False):  # some developer files need trimming
  try:
    response = requests.get(url)
    response.raise_for_status()
    tmp = response.text
# new
#    print(len(encoding.encode(tmp)))  # actual number of tokens?
#    print(len(tmp))
#
    #print(len(tmp))    # FIXME -- shoould we use the len(encode.encode(tmp)) instead of len(tmp) for test:
    if (len(tmp)>30000) & trim: 
      tmp = tmp[0:30000:1]  # avoid rate limiting error, could be too strict
    #print(len(tmp))
    return tmp
  except requests.exceptions.RequestException as e:
    print(f"Error fetching URL: {e}")
    return None


# Base schema completion

def schema_completion(content, schema, temp):
  completion=client.chat.completions.create(
    model=MODEL,
    temperature = temp,
    messages=[
      {"role": "system", "content": "You are a helpful expert in data curation and data modeling, especially with structured JSON data." + 
       "You return only valid JSON string, not in a code block, and without any other explanation so that the string and decoded and inserted into a database."},
      {"role": "user", "content": "Given content about a bioformatics tool, represent it as a JSON object compliant with the provided schema:" +
       "\nCONTENT:\n\n" + content + '\nSCHEMA:\n\n' + schema}]
  )
  return(completion)

# Validate and send any error to be corrected (default: max of 3 times), based on validation error

def fix_completion(content, error):
#  print(content)
  completion=client.chat.completions.create(
    model=MODEL,
    messages=[
      {"role": "system", "content": "You are debugging an API. Review the given JSON object and schema error and return the corrected JSON object only. Do not use code blocks."},
      {"role": "user", "content": "JSON:\n\n" + content + "\nSchema ERROR:\n\n" + error }]
  )
  return(completion)

def validate_json_with_retries(json_string, schema, max_retries=3, attempts=0):
    if attempts > max_retries:
        raise Exception(f"Failed to validate JSON after {max_retries} attempts")
    try:
        parsed_json = json.loads(json_string)
        validate(instance=parsed_json, schema=schema)
        
        # Both JSON parsing and validation succeeded
        print("Success after", attempts, "attempts")
        return parsed_json
    except (json.JSONDecodeError, ValidationError) as e:
        attempts += 1
        print("JSON not valid, trying QC/correction prompt, attempt", attempts)
        if attempts == max_retries:
            raise
        response = fix_completion(json_string, str(e))
        json_string = response.choices[0].message.content
        validate_json_with_retries(json_string, schema, max_retries, attempts)
    

# https://openai.com/api/pricing/
# Note: minimum cost, ignores cached tokens and completions for QC re-prompts

def openai_completion_cost(usage):
    input_pricing_per_token = 0.0000025
    output_pricing_per_token = 0.00001
    total = (usage.prompt_tokens * input_pricing_per_token) + (usage.completion_tokens * output_pricing_per_token)
    return(total)

def transform_with_uri(terms, subset):
     result = [{ "term" : term["term"], "uri": loaded_reference[subset][term.get("term")]} for term in terms]
     return result

def transform_terms(data):
    new_data = {}
    if isinstance(data, dict):
        for key, value in data.items():
            if key in ("operation", "topic", "format"):
                new_data[key] = [{ "term" : term["term"], "uri": loaded_reference[key][term.get("term")]} for term in value]
            elif key == "data":
                new_data[key] = { "term" : value["term"], "uri": loaded_reference[key][value["term"]]}
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
    

