<?php
// FILE: delete.php
// Remove livro pelo ID via DELETE ou POST (com _method=DELETE)

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/src/BookModel.php';

$model = new BookModel(__DIR__ . '/db/books.db');

$method = $_SERVER['REQUEST_METHOD'];

// ---------------------------
// Leitura de input
// ---------------------------
$data = [];

// DELETE puro → vem via php://input
if ($method === 'DELETE') {
    parse_str(file_get_contents('php://input'), $data);
}
// POST → pode vir JSON ou x-www-form-urlencoded
else if ($method === 'POST') {
    $json = json_decode(file_get_contents('php://input'), true);
    $data = $json ?? $_POST;
}

// ---------------------------
// ID obrigatório
// ---------------------------
$id = isset($data['id']) ? intval($data['id']) : null;

if (!$id) {
    http_response_code(400);
    echo json_encode(['error' => 'id required']);
    exit;
}

// ---------------------------
// Executa exclusão
// ---------------------------
$ok = $model->delete($id);

echo json_encode(['ok' => $ok]);
