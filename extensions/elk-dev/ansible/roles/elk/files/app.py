import requests, os, json, zipfile, time, socket
from datetime import datetime
from flask import Flask, request, Response, render_template_string, send_file, jsonify

EXPORT_FOLDER = '/opt/flask_app/exports'

os.makedirs(EXPORT_FOLDER, exist_ok=True)
app = Flask(__name__)

def export_es_data(name):
    """Exports an index or a data stream from Elasticsearch using Scroll API."""
    search_endpoint = f"http://localhost:9200/{name}/_search?scroll=1m"
    headers = {"Content-Type": "application/json"}
    doc_count = 0
    # Initial search request
    query = {"size": 1000, "query": {"match_all": {}}}
    response = requests.post(search_endpoint, json=query, headers=headers)
    data = response.json()
    
    if "hits" not in data:
        return None  # No data found

    with open(f'{EXPORT_FOLDER}/{name}.ndjson', 'w') as f:
        scroll_id = data["_scroll_id"]
        while True:
            hits = data.get("hits", {}).get("hits", [])
            if not hits:
                break
            for doc in hits:
                f.write(json.dumps(doc["_source"]) + "\n")
                doc_count += 1
            
            # Get next batch
            scroll_response = requests.post(f"http://localhost:9200/_search/scroll", json={"scroll": "1m", "scroll_id": scroll_id}, headers=headers)
            data = scroll_response.json()

        print(f'Got: {doc_count} documents')

def zip_logs(filename):
    print(f'{EXPORT_FOLDER}/{filename}')
    zf = zipfile.ZipFile(f'{EXPORT_FOLDER}/{filename}', "w")

    os.chdir(EXPORT_FOLDER)
    for file in os.listdir(EXPORT_FOLDER):
        if file == filename:
            continue
        zf.write(file)
    zf.close()
    return True

def get_indices_and_data_streams():
    indices = requests.get("http://localhost:9200/_cat/indices?format=json").json()
    ds = requests.get("http://localhost:9200/_data_stream/*/_stats?format=json").json()['data_streams']
    sources_indices = []
    sources_ds = []

    print(f"Found {len(indices)} indices")
    print(f"Found {len(ds)} data streams")

    for index in indices:
        sources_indices.append({'name': index['index'], 'size': index['store.size']})

    for stream in ds:
        print(stream)
        sources_ds.append({'name': stream['data_stream'], 'size': str(round(stream['store_size_bytes'] / 1000000, 2)) + 'mb'})

    return sources_indices, sources_ds

@app.route('/')
def home():
   
    indices, ds = get_indices_and_data_streams()
    hidden_indices = [index for index in indices if index['name'].startswith('.')]
    visible_indices = [index for index in indices if not index['name'].startswith('.')]

    return render_template_string("""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Elasticsearch Data Export</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; }
            .container { width: 300px; margin: auto; }
            .item { display: flex; align-items: center; margin: 5px 0; }
            button { background-color: #28a745; color: white; border: none; padding: 10px; cursor: pointer; margin-top: 10px; }
            button:hover { background-color: #218838; }
            #download-link { display: none; margin-top: 10px; }
        </style>
    </head>
    <body>
        <h1>Elasticsearch Data Export</h1>
        
        <h2>Available Sources</h2>
        
        <form id="selectionForm">
            <div class="container">
                <h3>Indices</h3>
                <input type="checkbox" id="toggle-hidden"> Show Hidden Indices
                
                <div id="visible-indices">
                    {% for index in visible_indices %}
                        <div class="item">
                            <input type="checkbox" name="sources" value="{{ index['name'] }}">
                            <label>{{ index['name'] }} ({{ index['size'] }})</label>
                        </div>
                    {% endfor %}
                </div>

                <div id="hidden-indices" style="display: none;">
                    {% for index in hidden_indices %}
                        <div class="item hidden">
                            <input type="checkbox" name="sources" value="{{ index['name'] }}">
                            <label>{{ index['name'] }} ({{ index['size'] }})</label>
                        </div>
                    {% endfor %}
                </div>

                <h3>Data Streams</h3>
                {% for stream in ds %}
                    <div class="item">
                        <input type="checkbox" name="sources" value="{{ stream['name'] }}">
                        <label>{{ stream['name'] }} ({{ stream['size'] }})</label>
                    </div>
                {% endfor %}
                <p></p>
                <button type="submit">Download</button>
            </div>
        </form>
        <p id="loading" style="display: none;">Processing...</p>
        <a id="download-link" href="#" download>Download File</a>

        <button id="clear-btn">Clear All Files</button>

        <script>
            document.getElementById("selectionForm").addEventListener("submit", function(event) {
                event.preventDefault();  // Prevent form submission

                // Get selected sources
                let selectedSources = [];
                document.querySelectorAll("input[name='sources']:checked").forEach(source => {
                    selectedSources.push(source.value);
                });

                if (selectedSources.length === 0) {
                    alert("Please select at least one source.");
                    return;
                }

                // Show loading message
                document.getElementById("loading").style.display = "block";
                document.getElementById("download-link").style.display = "none";

                // Send data to Flask server
                fetch("/process", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ sources: selectedSources })
                })
                .then(response => response.json())
                .then(data => {
                    document.getElementById("loading").style.display = "none";

                    if (data.file_url) {
                        let downloadLink = document.getElementById("download-link");
                        downloadLink.href = data.file_url;
                        downloadLink.style.display = "block";
                        // Automatically start the download
                        downloadLink.click();
                    } else {
                        alert("Error processing request.");
                    }
                })
                .catch(error => {
                    document.getElementById("loading").style.display = "none";
                    alert("An error occurred.");
                    console.error(error);
                });
            });
            document.getElementById("clear-btn").addEventListener("click", function() {
                if (!confirm("Are you sure you want to delete all files?")) {
                    return;
                }

                fetch("/clear", { method: "POST" })
                .then(response => response.json())
                .then(data => {
                    if (data.message) {
                        alert(data.message);
                        document.getElementById("download-link").style.display = "none";
                    } else {
                        alert("Error: " + data.error);
                    }
                })
                .catch(error => {
                    alert("An error occurred.");
                    console.error(error);
                });
            });
            document.getElementById("toggle-hidden").addEventListener("change", function() {
                let hiddenDiv = document.getElementById("hidden-indices");
                if (this.checked) {
                    hiddenDiv.style.display = "block";
                } else {
                    hiddenDiv.style.display = "none";
                }
            });
        </script>
    </body>
    </html>
    """, visible_indices=visible_indices, hidden_indices=hidden_indices, ds=ds)

@app.route('/process', methods=['POST'])
def process():
    selected_sources = request.json.get('sources', [])  # Get selected sources from JSON data
    if not selected_sources:
        return jsonify({'error': 'No sources selected'}), 400
    
    for file in os.listdir(EXPORT_FOLDER):
        file_path = os.path.join(EXPORT_FOLDER, file)
        if os.path.isfile(file_path):
            os.remove(file_path)
    # Simulate processing time (e.g., database operations, file generation)
    for source in selected_sources:
        export_es_data(source)

    timestamp = datetime.now()
    timestamp = timestamp.strftime("%d-%m-%y-%H%M%S")

    archive_name = socket.gethostname() + timestamp + '.zip'

    zip_logs(archive_name)

    file_path = f'{EXPORT_FOLDER}/{archive_name}'

    return jsonify({'file_url': f'/download?filename={file_path}'})  # Send file URL for download

@app.route('/download')
def download():
    filename = request.args.get('filename')
    return send_file(filename, as_attachment=True)

@app.route('/clear', methods=['POST'])
def clear_directory():
    try:
        for file in os.listdir(EXPORT_FOLDER):
            file_path = os.path.join(EXPORT_FOLDER, file)
            if os.path.isfile(file_path):
                os.remove(file_path)
        return jsonify({'message': 'Directory Cleared Successfully!'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")