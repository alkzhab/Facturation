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

$success = '';
$error = '';
$facture_numero = $_GET['facture'] ?? '';

if ($facture_numero) {
    // On utilise la vue pour l'affichage facile
    $stmt = $pdo->prepare("SELECT * FROM vue_facture WHERE numero_document = :num");
    $stmt->execute([':num' => $facture_numero]);
    $facture = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($facture) {
        $stmt = $pdo->prepare("SELECT * FROM vue_factureligne WHERE numero_facture = :num");
        $stmt->execute([':num' => $facture_numero]);
        $lignes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $has_lines = false;
        foreach ($_POST['lignes'] as $quantite) {
            if ($quantite > 0) {
                $has_lines = true;
                break;
            }
        }
        
        if (!$has_lines) {
            $error = "Veuillez sélectionner au moins une ligne à rembourser";
        } else {
            $pdo->beginTransaction();

            // 1. CRÉATION DE L'AVOIR (Entête)
            // CORRECTION ERREUR 1364 : On fournit '' pour numero_document
            $stmt = $pdo->prepare("INSERT INTO facture (
                                   numero_document, 
                                   nom_client, code_client, civilite_client,
                                   adresse_facturation, code_postal_facturation, ville_facturation, code_pays_facturation,
                                   total_brut_ht, remise_pct, remise_montant, 
                                   escompte_pct, escompte_montant, frais_port_ht, total_ttc, 
                                   code_commercial, code_mode_reglement, validation
                                   ) 
                                   SELECT 
                                   '', -- On passe vide pour que le Trigger génère le numéro AV...
                                   nom_client, code_client, civilite_client,
                                   adresse_facturation, code_postal_facturation, ville_facturation, code_pays_facturation,
                                   -total_brut_ht, remise_pct, -remise_montant, 
                                   escompte_pct, -escompte_montant, -frais_port_ht, -total_ttc, 
                                   code_commercial, code_mode_reglement, 0
                                   FROM facture WHERE numero_document = :num_facture");
            
            $stmt->execute([':num_facture' => $_POST['numero_facture']]);
            
            // Récupérer le numéro généré par le trigger
            // (La dernière facture créée est forcément notre avoir)
            $stmt = $pdo->query("SELECT numero_document FROM facture ORDER BY numero_document DESC LIMIT 1");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            $numero_avoir = $result['numero_document'];

            // 2. CRÉATION DES LIGNES D'AVOIR
            foreach ($_POST['lignes'] as $id_ligne => $quantite) {
                if ($quantite > 0) {
                    // On insère les lignes en négatif
                    // On calcule le total_ligne_ht manuellement car la vue le fait d'habitude
                    $stmt = $pdo->prepare("INSERT INTO factureligne (
                                           numero_facture, code_article, description_article, 
                                           quantite, prix_ht, taux_tva, total_ligne_ht
                                           )
                                           SELECT 
                                           :num_avoir, code_article, description_article, 
                                           -:quantite, prix_ht, taux_tva, (prix_ht * -:quantite)
                                           FROM factureligne WHERE id_factureLigne = :id_ligne");
                    
                    $stmt->execute([
                        ':num_avoir' => $numero_avoir,
                        ':quantite' => $quantite,
                        ':id_ligne' => $id_ligne
                    ]);
                }
            }

            $pdo->commit();
            $success = "Avoir <strong>$numero_avoir</strong> créé avec succès !";
        }
    } catch (Exception $e) {
        $pdo->rollBack();
        $error = "Erreur SQL : " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Générer un Avoir</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Générer un Avoir</h1>
            <a href="index.php" class="btn back-btn">← Retour</a>
        </div>

        <?php if ($success): ?>
            <div class="success"><?= $success ?></div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="error"><?= $error ?></div>
        <?php endif; ?>

        <?php if (isset($facture)): ?>
        <div class="section-container">
            <h2 class="section-title">Facture d'origine : <?= htmlspecialchars($facture['numero_document']) ?></h2>
            <div class="summary-item">
                <span>Client:</span>
                <strong><?= htmlspecialchars($facture['nom_client']) ?></strong>
            </div>
            <div class="summary-item">
                <span>Date:</span>
                <strong><?= htmlspecialchars($facture['date_document']) ?></strong>
            </div>
            <div class="summary-item">
                <span>Total TTC:</span>
                <strong><?= number_format((float)str_replace(',', '.', $facture['total_facture_ttc']), 2, ',', ' ') ?> €</strong>
            </div>
        </div>

        <form method="POST" class="section-container">
            <h2 class="section-title">Articles à rembourser</h2>
            <p style="margin-bottom: 1rem; color: #666;">Indiquez la quantité à reprendre pour chaque article (0 = pas de reprise).</p>
            <input type="hidden" name="numero_facture" value="<?= htmlspecialchars($facture['numero_document']) ?>">
            
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Article</th>
                        <th>Description</th>
                        <th>Qté facturée</th>
                        <th>Prix HT</th>
                        <th>Qté à rembourser</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($lignes as $ligne): ?>
                    <tr>
                        <td><?= htmlspecialchars($ligne['code_article']) ?></td>
                        <td><?= htmlspecialchars(clean_rtf($ligne['description_article'])) ?></td>
                        <td><?= htmlspecialchars($ligne['quantite']) ?></td>
                        <td><?= number_format((float)str_replace(',', '.', $ligne['prix_ht']), 2, ',', ' ') ?> €</td>
                        <td>
                            <input type="number" name="lignes[<?= $ligne['id_factureLigne'] ?>]" 
                                   min="0" max="<?= (float)str_replace(',', '.', $ligne['quantite']) ?>" value="0" step="0.01" 
                                   style="width: 100px; padding: 5px;">
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>

            <div style="margin-top: 2rem; text-align: right;">
                <button type="submit" class="btn btn-primary">Valider et créer l'Avoir</button>
            </div>
        </form>
        <?php else: ?>
        <div class="section-container">
            <p>Facture introuvable. Retournez à la <a href="index.php">liste des factures</a>.</p>
        </div>
        <?php endif; ?>
    </div>
</body>
</html>