import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';

const ssmClient = new SSMClient();

/**
 * Retrieves the NASA Astronomy Picture of the Day from the NASA APOD API
 *
 * @param {Object} event - AWS Lambda event object from API Gateway
 * @returns {Object} Response object with statusCode, headers, and body
 * @returns {number} response.statusCode - HTTP status code (200 for success, 500 for errors)
 * @returns {Object} response.headers - Response headers including CORS headers
 * @returns {string} response.body - JSON stringified response body
 */
export async function getNasaImage(event) {
  const keyPath = process.env.NASA_API_KEY_PATH;
  const apiUrl = process.env.NASA_API_URL;

  try {
    // Retrieve API key from SSM Parameter Store
    const apiKey = await fetchApiKey(keyPath);

    // Call the NASA APOD API with the retrieved API key
    const response = await fetch(`${apiUrl}?api_key=${apiKey}`, {
      headers: { Accept: "application/json" }
    });

    if (!response.ok) {
      throw new Error(`NASA API responded with status ${response.status}`);
    }

    const data = await response.json();

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        title: data.title,
        url: data.url,
        explanation: data.explanation,
        date: data.date,
        mediaType: data.media_type
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        error: "Failed to fetch NASA image of the day",
        message: error.message
      }),
    };
  }
}

/**
 * Fetches an API key from AWS SSM Parameter Store
 *
 * @param {string} keyPath - Path to the API key in Parameter Store
 * @returns {Promise<string>} The API key value
 * @throws {Error} If the API key cannot be retrieved
 */
async function fetchApiKey(keyPath) {
  const getParameterCommand = new GetParameterCommand({
    Name: keyPath,
    WithDecryption: true
  });

  const response = await ssmClient.send(getParameterCommand);

  return response.Parameter.Value;
}
