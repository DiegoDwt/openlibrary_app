<?php
// helpers.php - funções utilitárias

function jsonBody() {
    $data = json_decode(file_get_contents('php://input'), true);
    return $data ?? [];
}

function respond($payload, $status = 200) {
    http_response_code($status);
    echo json_encode($payload);
    exit;
}
