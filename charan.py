from flask import Flask, Response
from azure.storage.blob import BlobServiceClient
import os

app = Flask(__name__)

CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=nextopsat10;AccountKey=FhdrPBweex2e5WVoALIcMzUOpJ7BbW1vohNktrzUPBibJG1aL7y1f1PsmC9dMxAmnwY6INdjyTys+ASt4YPHuQ==;EndpointSuffix=core.windows.net"
CONTAINER_NAME = "data"
BLOB_NAME = "data.json"

@app.route('/')
def landing():
    return "This is a test app"

@app.route('/api/json')
def get_json_content():
    blob = BlobServiceClient.from_connection_string(CONNECTION_STRING)\
        .get_blob_client(container=CONTAINER_NAME, blob=BLOB_NAME)
    content = blob.download_blob().readall().decode('utf-8')
    return Response(content, content_type='application/json')

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
