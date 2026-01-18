<?php
require_once 'config.php';

$success = '';
$error = '';
$code_tiers = $_GET['code'] ?? '';

// Récupération des infos client et adresse facturation
if ($code_tiers) {
    $stmt = $pdo->prepare("SELECT * FROM client WHERE code_tiers = :code");
    $stmt->execute([':code' => $code_tiers]);
    $client = $stmt->fetch(PDO::FETCH_ASSOC);

    $stmt = $pdo->prepare("SELECT * FROM adresse_facturation WHERE code_tiers = :code");
    $stmt->execute([':code' => $code_tiers]);
    $adresse_fact = $stmt->fetch(PDO::FETCH_ASSOC);
}

// Traitement du formulaire
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->beginTransaction();

        // 1. Mise à jour de la table CLIENT
        $stmt = $pdo->prepare("UPDATE client SET nom = :nom, civilite = :civilite WHERE code_tiers = :code");
        $stmt->execute([
            ':nom' => $_POST['nom'],
            ':civilite' => $_POST['civilite'],
            ':code' => $_POST['code_tiers']
        ]);

        // 2. Mise à jour de la table ADRESSE_FACTURATION
        // Correction : on utilise 'adresse' et 'telephone_fixe' comme dans votre BDD
        $stmt = $pdo->prepare("UPDATE adresse_facturation SET 
                               adresse = :adresse, 
                               code_postal = :code_postal, 
                               ville = :ville, 
                               telephone_fixe = :telephone, 
                               email = :email 
                               WHERE code_tiers = :code");
        $stmt->execute([
            ':adresse' => $_POST['adresse'], // C'était 'adresse1' avant
            ':code_postal' => $_POST['code_postal'],
            ':ville' => $_POST['ville'],
            ':telephone' => $_POST['telephone'],
            ':email' => $_POST['email'],
            ':code' => $_POST['code_tiers']
        ]);

        $pdo->commit();
        $success = "Client modifié avec succès";
        
        // Rechargement des données pour affichage
        $stmt = $pdo->prepare("SELECT * FROM client WHERE code_tiers = :code");
        $stmt->execute([':code' => $_POST['code_tiers']]);
        $client = $stmt->fetch(PDO::FETCH_ASSOC);

        $stmt = $pdo->prepare("SELECT * FROM adresse_facturation WHERE code_tiers = :code");
        $stmt->execute([':code' => $_POST['code_tiers']]);
        $adresse_fact = $stmt->fetch(PDO::FETCH_ASSOC);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        $error = "Erreur : " . $e->getMessage();
    }
}

// Liste pour le menu déroulant
$stmt = $pdo->query("SELECT code_tiers, nom FROM client ORDER BY nom LIMIT 50");
$clients = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Modifier Client</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Modification Client</h1>
            <a href="index.php" class="btn back-btn">← Retour</a>
        </div>

        <?php if ($success): ?>
            <div class="success"><?= $success ?></div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="error"><?= $error ?></div>
        <?php endif; ?>

        <div class="section-container">
            <h2 class="section-title">Sélectionner un client</h2>
            <form method="GET">
                <div class="form-group">
                    <label>Client</label>
                    <select name="code" onchange="this.form.submit()">
                        <option value="">-- Sélectionner --</option>
                        <?php foreach ($clients as $c): ?>
                        <option value="<?= htmlspecialchars($c['code_tiers']) ?>" 
                                <?= $code_tiers === $c['code_tiers'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($c['code_tiers']) ?> - <?= htmlspecialchars($c['nom']) ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </form>
        </div>

        <?php if (isset($client)): ?>
        <form method="POST" class="section-container">
            <h2 class="section-title">Informations client</h2>
            <input type="hidden" name="code_tiers" value="<?= htmlspecialchars($client['code_tiers']) ?>">
            
            <div class="form-row">
                <div class="form-group">
                    <label>Civilité</label>
                    <input type="text" name="civilite" value="<?= htmlspecialchars($client['civilite']) ?>">
                </div>
                <div class="form-group">
                    <label>Nom</label>
                    <input type="text" name="nom" value="<?= htmlspecialchars($client['nom']) ?>" required>
                </div>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label>Adresse</label>
                    <input type="text" name="adresse" value="<?= htmlspecialchars($adresse_fact['adresse'] ?? '') ?>">
                </div>
                <div class="form-group">
                    <label>Code Postal</label>
                    <input type="text" name="code_postal" value="<?= htmlspecialchars($adresse_fact['code_postal'] ?? '') ?>">
                </div>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label>Ville</label>
                    <input type="text" name="ville" value="<?= htmlspecialchars($adresse_fact['ville'] ?? '') ?>">
                </div>
                <div class="form-group">
                    <label>Téléphone Fixe</label>
                    <input type="tel" name="telephone" value="<?= htmlspecialchars($adresse_fact['telephone_fixe'] ?? '') ?>">
                </div>
            </div>

            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" value="<?= htmlspecialchars($adresse_fact['email'] ?? '') ?>">
            </div>

            <button type="submit" class="btn btn-primary">Enregistrer les modifications</button>
        </form>
        <?php endif; ?>
    </div>
</body>
</html>