<?php
// ============================================================================
// CONFIGURAÇÕES INICIAIS
// ============================================================================
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=utf-8");

// Carrega o modelo
require_once __DIR__ . "/src/BookModel.php";

// Caminho do banco
$dbFile = __DIR__ . "/books.db";

// Instancia o modelo
$model = new BookModel($dbFile);

// Mostra debug ao acessar API diretamente
echo "DB FILE: $dbFile\nBanco existe!\nConexão OK!\n";

// ============================================================================
// ROTEAMENTO
// ============================================================================
$path = $_GET['path'] ?? null;
$method = $_SERVER['REQUEST_METHOD'];

// Se nenhum path → mostra rota padrão
if (!$path) {
    echo json_encode([
        "status" => "API funcionando",
        "exemplo_listar" => "/api.php?path=books",
        "exemplo_get" => "/api.php?path=books&id=1"
    ], JSON_PRETTY_PRINT);
    exit;
}

// ============================================================================
// ENDPOINT: /books
// ============================================================================
if ($path === "books") {

    // GET - listar ou buscar por id
    if ($method === "GET") {

        if (isset($_GET["id"])) {
            $book = $model->get($_GET["id"]);
            echo json_encode($book ?: []);
            exit;
        }

        // list all
        echo json_encode($model->list());
        exit;
    }

    // POST - inserir livro
    if ($method === "POST") {
        $body = json_decode(file_get_contents("php://input"), true);

        if (!$body) {
            echo json_encode(["error" => "JSON inválido"]);
            exit;
        }

        echo json_encode($model->insertFromArray($body));
        exit;
    }

    // PUT - atualizar livro
    if ($method === "PUT") {
        if (!isset($_GET["id"])) {
            echo json_encode(["error" => "ID obrigatório"]);
            exit;
        }

        $body = json_decode(file_get_contents("php://input"), true);

        echo json_encode([
            "ok" => $model->update($_GET["id"], $body)
        ]);
        exit;
    }

    // DELETE - apagar
    if ($method === "DELETE") {
        if (!isset($_GET["id"])) {
            echo json_encode(["error" => "ID obrigatório"]);
            exit;
        }

        echo json_encode([
            "ok" => $model->delete($_GET["id"])
        ]);
        exit;
    }

    echo json_encode(["error" => "Método não suportado"]);
    exit;
}

echo json_encode(["error" => "Rota inválida"]);
exit;

