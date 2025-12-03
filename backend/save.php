<?php
// save.php - endpoint para inserir livro (versão defensiva para debug)

require_once __DIR__ . '/src/BookModel.php';

// Headers obrigatórios para API JSON
header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Pré-flight CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Lê corpo JSON
$rawBody = file_get_contents('php://input');

// DEBUG: grava o JSON recebido (substitui debug_save.txt a cada request)
file_put_contents(__DIR__ . '/debug_save.txt', $rawBody);

// tenta decodificar
$body = json_decode($rawBody, true);

if ($body === null && json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'error' => 'JSON inválido',
        'details' => json_last_error_msg()
    ]);
    exit;
}

// Cria modelo e tenta inserir com capture de exceções
try {
    $model = new BookModel(__DIR__ . '/db/books.db');
    $res = $model->insertFromArray($body);

    if (isset($res['ok']) && $res['ok'] === true) {
        http_response_code(201);
        echo json_encode(['id' => $res['id']]);
        exit;
    }

    // caso insertFromArray retornou erro controlado
    http_response_code(400);
    echo json_encode([
        'error' => $res['error'] ?? 'Erro desconhecido ao salvar'
    ]);
    exit;
} catch (Throwable $e) {
    // grava stack trace para debug
    $err = sprintf("[%s] Exception: %s\nFile: %s:%d\nStack:\n%s\n\n",
        date('c'), $e->getMessage(), $e->getFile(), $e->getLine(), $e->getTraceAsString());
    file_put_contents(__DIR__ . '/debug_save_error.txt', $err, FILE_APPEND);

    // responde 500 com mensagem curta (não vaze stack em produção; isto é para debug)
    http_response_code(500);
    echo json_encode([
        'error' => 'Erro interno no servidor',
        'message' => $e->getMessage()
    ]);
    exit;
}
