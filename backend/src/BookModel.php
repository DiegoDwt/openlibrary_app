<?php
// ============================================================================
// BookModel.php
// Model responsável por gerenciar a tabela de livros baixados
// ============================================================================

class BookModel
{
    private $db;

    public function __construct($dbFile)
    {
        ini_set('display_errors', 0);
        ini_set('log_errors', 1);

        $this->db = new PDO('sqlite:' . $dbFile);
        $this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        $this->createTable();
    }

    // -------------------------------------------------------------------------
    // Criar tabela
    // -------------------------------------------------------------------------
    private function createTable()
    {
        $sql = "
            CREATE TABLE IF NOT EXISTS books (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                author TEXT,
                cover_url TEXT,
                source_url TEXT,
                file_path TEXT,
                downloaded_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        ";
        $this->db->exec($sql);
    }

    // -------------------------------------------------------------------------
    // Inserir livro a partir do array vindo da API
    // Agora aceita authors como array ou string
    // -------------------------------------------------------------------------
    public function insertFromArray($data)
{
    try {
        if (!is_array($data)) {
            return ['ok' => false, 'error' => 'Payload inválido: esperado JSON objeto'];
        }

        if (!isset($data['title']) || trim((string)$data['title']) === "") {
            return ['ok' => false, 'error' => 'Field "title" is required'];
        }

        // Normalização segura dos autores: aceita array ou string
        $authors = $data['authors'] ?? ($data['author'] ?? null);
        $author = null;
        if (is_array($authors)) {
            $clean = [];
            foreach ($authors as $a) {
                if (is_string($a) && trim($a) !== '') {
                    $clean[] = trim($a);
                } elseif (is_numeric($a)) {
                    $clean[] = (string)$a;
                }
                // ignora outros tipos
            }
            $author = count($clean) ? implode(", ", $clean) : null;
        } elseif (is_string($authors)) {
            $tmp = trim($authors);
            $author = $tmp === '' ? null : $tmp;
        }

        // Outros campos: tratar apenas strings ou null
        $title     = (string)$data['title'];
        $coverUrl  = null;
        if (isset($data['coverUrl']) && is_string($data['coverUrl']) && trim($data['coverUrl']) !== '') {
            $coverUrl = trim($data['coverUrl']);
        } elseif (isset($data['cover_url']) && is_string($data['cover_url']) && trim($data['cover_url']) !== '') {
            $coverUrl = trim($data['cover_url']);
        }

        $sourceUrl = null;
        if (isset($data['sourceUrl']) && is_string($data['sourceUrl']) && trim($data['sourceUrl']) !== '') {
            $sourceUrl = trim($data['sourceUrl']);
        } elseif (isset($data['source_url']) && is_string($data['source_url']) && trim($data['source_url']) !== '') {
            $sourceUrl = trim($data['source_url']);
        }

        $filePath = null;
        if (isset($data['file_path']) && is_string($data['file_path']) && trim($data['file_path']) !== '') {
            $filePath = trim($data['file_path']);
        }

        // Prepare e execute insert
        $sql = "
            INSERT INTO books (title, author, cover_url, source_url, file_path)
            VALUES (:title, :author, :cover_url, :source_url, :file_path);
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->bindValue(':title', $title, PDO::PARAM_STR);
        $stmt->bindValue(':author', $author, $author === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
        $stmt->bindValue(':cover_url', $coverUrl, $coverUrl === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
        $stmt->bindValue(':source_url', $sourceUrl, $sourceUrl === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
        $stmt->bindValue(':file_path', $filePath, $filePath === null ? PDO::PARAM_NULL : PDO::PARAM_STR);

        $ok = $stmt->execute();

        return [
            'ok' => $ok,
            'id' => $this->db->lastInsertId()
        ];
        } catch (Throwable $e) {
            // grava erro para debug
            $err = sprintf("[%s] insertFromArray error: %s in %s:%d\nTrace:\n%s\n\n",
                date('c'), $e->getMessage(), $e->getFile(), $e->getLine(), $e->getTraceAsString());
            file_put_contents(__DIR__ . '/../debug_model_error.txt', $err, FILE_APPEND);

            return ['ok' => false, 'error' => 'Exception: ' . $e->getMessage()];
        }
    }

    // -------------------------------------------------------------------------
    // Listar todos os livros
    // -------------------------------------------------------------------------
    public function list()
    {
        $sql = "SELECT * FROM books ORDER BY downloaded_at DESC";
        $stmt = $this->db->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // -------------------------------------------------------------------------
    // Buscar por ID
    // -------------------------------------------------------------------------
    public function get($id)
    {
        $sql = "SELECT * FROM books WHERE id = :id LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->bindValue(':id', $id);
        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // -------------------------------------------------------------------------
    // Atualizar
    // -------------------------------------------------------------------------
    public function update($id, $data)
    {
        // Normalização segura dos autores
        $authors = $data['authors'] ?? ($data['author'] ?? null);

        if (is_array($authors)) {
            // Garante que todos são strings
            $cleanAuthors = [];

            foreach ($authors as $a) {
                if (is_string($a) && trim($a) !== "") {
                    $cleanAuthors[] = trim($a);
                }
            }

            $author = count($cleanAuthors) ? implode(", ", $cleanAuthors) : null;
        } elseif (is_string($authors)) {
            $author = trim($authors);
            if ($author === "") $author = null;
        } else {
            $author = null;
        }

        $sql = "
            UPDATE books
            SET
                title      = :title,
                author     = :author,
                cover_url  = :cover_url,
                source_url = :source_url,
                file_path  = :file_path
            WHERE id = :id
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->bindValue(':id',         $id);
        $stmt->bindValue(':title',      $data['title'] ?? null);
        $stmt->bindValue(':author',     $author);
        $stmt->bindValue(':cover_url',  $data['cover_url'] ?? null);
        $stmt->bindValue(':source_url', $data['source_url'] ?? null);
        $stmt->bindValue(':file_path',  $data['file_path'] ?? null);

        return $stmt->execute();
    }

    // -------------------------------------------------------------------------
    // Remover
    // -------------------------------------------------------------------------
    public function delete($id)
    {
        $sql = "DELETE FROM books WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindValue(':id', $id);
        return $stmt->execute();
    }
}
