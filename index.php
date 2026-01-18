<?php
require_once 'config.php';

$filter_date = $_GET['filter_date'] ?? '';
$filter_client = $_GET['filter_client'] ?? '';

$sql = "SELECT numero_document, nom_client, date_document, total_facture_ttc 
        FROM vue_facture 
        WHERE 1=1";

if ($filter_date) {
    // Convertir yyyy-mm-dd en dd/mm/yyyy
    $date_parts = explode('-', $filter_date);
    $filter_date_formatted = $date_parts[2] . '/' . $date_parts[1] . '/' . $date_parts[0];
    $sql .= " AND date_document = :filter_date";
}
if ($filter_client) {
    $sql .= " AND nom_client LIKE :filter_client";
}

$stmt = $pdo->prepare($sql);
if ($filter_date) $stmt->bindValue(':filter_date', $filter_date_formatted);
if ($filter_client) $stmt->bindValue(':filter_client', '%' . $filter_client . '%');
$stmt->execute();
$factures = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Liste des Factures</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Gestion Factures</h1>
        </div>

        <div class="section-container">
            <h2 class="section-title">Liste des Factures</h2>
            
            <form method="GET" class="form-row" style="margin-bottom: 2rem;">
                <div class="form-group">
                    <label>Date</label>
                    <input type="date" name="filter_date" value="<?= htmlspecialchars($filter_date) ?>">
                </div>
                <div class="form-group">
                    <label>Client</label>
                    <input type="text" name="filter_client" value="<?= htmlspecialchars($filter_client) ?>" placeholder="Nom du client">
                </div>
                <div class="form-group" style="display: flex; align-items: flex-end; gap: 1rem;">
                    <button type="submit" class="btn btn-primary">Filtrer</button>
                    <a href="index.php" class="btn btn-secondary">Réinitialiser</a>
                    <a href="modifier_client.php" class="btn btn-secondary">Modifier Client</a>
                </div>
            </form>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>Numéro</th>
                        <th>Client</th>
                        <th>Date</th>
                        <th>Total TTC</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($factures as $f): ?>
                    <tr>
                        <td>
                            <a href="detail_facture.php?numero=<?= urlencode($f['numero_document']) ?>" style="color: #ff7b54; text-decoration: none; font-weight: 600;">
                                <?= htmlspecialchars($f['numero_document']) ?>
                            </a>
                        </td>
                        <td><?= htmlspecialchars($f['nom_client']) ?></td>
                        <td><?= htmlspecialchars($f['date_document']) ?></td>
                        <td><?= number_format((float)str_replace(',', '.', $f['total_facture_ttc']), 2, ',', ' ') ?> €</td>
                        <td>
                            <a href="generer_avoir.php?facture=<?= urlencode($f['numero_document']) ?>" class="btn btn-small btn-secondary">Créer Avoir</a>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>