
function importFormHandler() {
    console.log("Import form JS loaded");
    const form = document.querySelector('[data-controller="import-form"]');
    if (!form) return;

    form.addEventListener("submit", handleSubmit);
}

document.addEventListener("DOMContentLoaded", importFormHandler);
document.addEventListener("turbo:load", importFormHandler);

function handleSubmit(e) {
    e.preventDefault();

    const form = e.target;
    const headers = getHeaders();
    const formData = new FormData(form);


    const data = {
        yamlFile: formData.get("import[yaml_content]"),
        csvFile: formData.get("import[csv_file]"),
        importType: formData.get("import[import_type]")
    }

    if (!data.yamlFile || !data.csvFile || !data.importType) {
        notify('alert',"Both fields are required.");
        return;
    }



    uploadYaml(data, form.action, headers)
        .then(({ presigned_url, file_key, import_id }) => {
            return uploadCsvToMinio(presigned_url, data.csvFile).then(() => ({ file_key, import_id }));
        })
        .then(({ file_key, import_id }) => {
            return notifyBackend(import_id, file_key, headers);
        })
        .then(() => {
            setTimeout(() => window.location.replace("/imports"), 200)

            notify('notice', 'Successfully uploaded. Import processing starting soon.')
        })
        .catch(error => {
            if (error.errors?.length) {
                notify('alert', error.errors.join(','))
            } else
                notify('alert', error.message || "An unexpected error occurred");
        });
}

function getHeaders() {
    return {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
        "Accept": "application/json",
    };
}

function uploadYaml(data, action, headers) {
    const yamlUploadFormData = new FormData();
    yamlUploadFormData.append("import[yaml_content]", data.yamlFile);
    yamlUploadFormData.append("import[import_type]", data.importType);

    return fetch(action, {
        method: "POST",
        headers: headers,
        body: yamlUploadFormData,
    })
        .then(response => {
            if (!response.ok) return response.json().then(err => Promise.reject(err));
            return response.json();
        });
}

function uploadCsvToMinio(url, file) {
    return fetch(url, {
        method: "PUT",
        headers: { "Content-Type": "text/csv" },
        body: file,
    }).then(response => {
        if (!response.ok) throw new Error("CSV upload to MinIO failed");
        return response;
    });
}

function notifyBackend(import_id, file_key, headers) {
    return fetch("/imports/uploaded", {
        method: "POST",
        headers: {
            ...headers,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ id: import_id, file_key }),
    }).then(response => {
        if (!response.ok) throw new Error("Failed to upload to server");
        return response.json();
    });
}
