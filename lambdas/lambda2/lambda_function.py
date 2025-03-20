import os
import json
import urllib.request

def get_random_quote(event, context):
  """
  Retrieves a random inspirational quote from ZenQuotes.io API

  Parameters:
  - event: API Gateway event data
  - context: Lambda runtime information

  Returns:
  - 200: Successful response with quote data (JSON with quote, author, source)
  - 502: Invalid response from quotes API or JSON parsing error
  - 5xx: Server errors from the quotes API or connection issues
  """

  try:
    # Making request to the API
    quotes_api_url = os.environ.get('QUOTES_API_URL', 'https://zenquotes.io/api/random')
    req = urllib.request.Request(quotes_api_url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as response:
      data = response.read().decode('utf-8')

    # Extracting data from the response
    quote_data = json.loads(data)
    if quote_data and len(quote_data) > 0:
      quote = quote_data[0]['q']
      author = quote_data[0]['a']
      result = {
        'quote': quote,
        'author': author,
        'source': 'ZenQuotes.io'
      }

      return {
        'statusCode': 200,
        'headers': {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(result)
      }
    else:
      return {
        'statusCode': 502,
        'body': json.dumps({'error': 'Invalid response from quotes API'})
      }
  except urllib.error.HTTPError as e:
    return {
      'statusCode': e.code,
      'body': json.dumps({'error': f"HTTP Error: {e.reason}"})
    }
  except urllib.error.URLError as e:
    return {
        'statusCode': 500,
        'body': json.dumps({'error': f"Connection error: {e.reason}"})
    }
  except json.JSONDecodeError as e:
    return {
      'statusCode': 502,
      'body': json.dumps({'error': "Invalid JSON response from quotes API"})
    }
  except Exception as e:
    return {
      'statusCode': 500,
      'body': json.dumps({'error': f"Server error: {str(e)}"})
    }
