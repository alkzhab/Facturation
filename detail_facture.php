<?php
require_once 'config.php';

// Fonction pour nettoyer le RTF
function clean_rtf($rtf) {
    if (empty($rtf)) return '';
    
    if (strpos($rtf, '{\rtf') === 0) {
        $text = preg_replace('/\{[^\}]*\}/', '', $rtf);
        $text = preg_replace('/\\\\[a-z]+[0-9]*\s?/', ' ', $text);
        $text = str_replace('\par', ' ', $text);
        $text = preg_replace('/\s+/', ' ', $text);
        return trim($text);
    }
    
    return $rtf;
}

$numero = $_GET['numero'] ?? '';
$facture = null;
$lignes = [];

if ($numero) {
    $stmt = $pdo->prepare("SELECT * FROM vue_facture WHERE numero_document = :num");
    $stmt->execute([':num' => $numero]);
    $facture = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($facture) {
        $stmt = $pdo->prepare("SELECT * FROM vue_factureligne WHERE numero_facture = :num");
        $stmt->execute([':num' => $numero]);
        $lignes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Détail Facture</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Détail de la Facture</h1>
            <a href="index.php" class="btn back-btn">← Retour</a>
        </div>

        <?php if ($facture): ?>
        <div class="section-container">
            <h2 class="section-title">Facture <?= htmlspecialchars($facture['numero_document']) ?></h2>
            
            <div class="summary-item">
                <span>Client:</span>
                <strong><?= htmlspecialchars($facture['nom_client']) ?></strong>
            </div>
            <div class="summary-item">
                <span>Date:</span>
                <strong><?= htmlspecialchars($facture['date_document']) ?></strong>
            </div>
            <div class="summary-item">
                <span>Commercial:</span>
                <strong><?= htmlspecialchars($facture['code_commercial']) ?></strong>
            </div>
            <div class="summary-item">
                <span>Mode de règlement:</span>
                <strong><?= htmlspecialchars($facture['code_mode_reglement']) ?></strong>
            </div>
        </div>

        <div class="section-container">
            <h2 class="section-title">Lignes de facture</h2>
            
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Article</th>
                        <th>Description</th>
                        <th>Quantité</th>
                        <th>Prix HT</th>
                        <th>TVA</th>
                        <th>Total HT</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($lignes as $ligne): ?>
                    <tr>
                        <td><?= htmlspecialchars($ligne['code_article']) ?></td>
                        <td><?= htmlspecialchars(clean_rtf($ligne['description_article'])) ?></td>
                        <td><?= htmlspecialchars($ligne['quantite']) ?></td>
                        <td><?= number_format((float)str_replace(',', '.', $ligne['prix_ht']), 2, ',', ' ') ?> €</td>
                        <td><?= htmlspecialchars($ligne['taux_tva']) ?>%</td>
                        <td><?= number_format((float)$ligne['total_ligne_ht'], 2, ',', ' ') ?> €</td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <div class="section-container">
            <h2 class="section-title">Totaux</h2>
            
            <div class="summary-item">
                <span>Total HT:</span>
                <strong><?= number_format((float)$facture['total_ht_calcule'], 2, ',', ' ') ?> €</strong>
            </div>
            <div class="summary-item">
                <span>Total TVA:</span>
                <strong><?= number_format((float)$facture['total_tva_calcule'], 2, ',', ' ') ?> €</strong>
            </div>
            <div class="summary-item">
                <span>Remise (<?= htmlspecialchars($facture['remise_pct']) ?>%):</span>
                <strong><?= number_format((float)str_replace(',', '.', $facture['remise_montant']), 2, ',', ' ') ?> €</strong>
            </div>
            <div class="summary-item">
                <span>Frais de port:</span>
                <strong><?= number_format((float)str_replace(',', '.', $facture['frais_port_ht']), 2, ',', ' ') ?> €</strong>
            </div>
            <div class="summary-item" style="border-top: 2px solid #333; padding-top: 1rem; margin-top: 1rem;">
                <span style="font-size: 1.2rem; font-weight: bold;">Total TTC:</span>
                <strong style="font-size: 1.5rem; color: #00b894;"><?= number_format((float)str_replace(',', '.', $facture['total_facture_ttc']), 2, ',', ' ') ?> €</strong>
            </div>
        </div>

        <div style="margin-top: 2rem; display: flex; gap: 1rem;">
            <a href="generer_avoir.php?facture=<?= urlencode($facture['numero_document']) ?>" class="btn btn-primary">Créer un avoir</a>
        </div>
        
        <?php else: ?>
        <div class="section-container">
            <p>Facture non trouvée.</p>
        </div>
        <?php endif; ?>
    </div>
</body>
</html>
