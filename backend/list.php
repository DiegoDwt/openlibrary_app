<?php
// list.php - retorna lista de livros salvos (JSON)

ini_set('display_errors', 0);   // não mostrar erros no output
ini_set('log_errors', 1);

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/src/BookModel.php';

try {
    $model = new BookModel(__DIR__ . '/db/books.db');
    $list = $model->list();

    // garantir que o retorno seja JSON limpo
    echo json_encode($list);
    exit;
} catch (Throwable $e) {
    // Log the error server-side
    error_log("list.php error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Erro interno no servidor']);
    exit;
}
