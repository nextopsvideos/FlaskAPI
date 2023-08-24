from flask import Flask, Response
from azure.storage.blob import BlobServiceClient

app = Flask(__name__)

# Replace with your Azure Blob Storage connection string
CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=nextopsat12;AccountKey=3tWRoEVKrkGJL9XZNhPdqVdKLiu5VYe1ooR85GDajmgkruxCoB84wacDOKIfRCCYCdox9a8WRrg8+AStd/fA6A==;EndpointSuffix=core.windows.net"
CONTAINER_NAME = "data"
BLOB_NAME = "charan.json"

@app.route('/json', methods=['GET'])
def get_json_content():
    try:
        blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
        blob_client = blob_service_client.get_blob_client(container=CONTAINER_NAME, blob=BLOB_NAME)
        blob_content = blob_client.download_blob().readall()

        json_content = blob_content.decode('utf-8')
        
        response = Response(json_content, content_type='application/json')
        return response

    except Exception as e:
        return ({"error": str(e)})

if __name__ == '__main__':
    app.run()
