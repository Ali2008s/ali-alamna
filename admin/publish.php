<?php
/**
 * Admin Publishing Dashboard for Streamit TV App - عالمنا
 * Features: Shorts Upload, News Control, Ads Management, Slider Control
 */

// ─── CONFIGURATION ────────────────────────────────────────────────────────────
$bot_token    = "8611923680:AAEP67ncVYEykIsagjlIYNgEMTNvBjnQZcc";
$chat_id      = "-1003554364945";
$firebase_base = "https://hnd9-db536-default-rtdb.firebaseio.com";
// ─────────────────────────────────────────────────────────────────────────────

$message = "";
$msgType = "success";

// ─── Firebase Helper ──────────────────────────────────────────────────────────
function firebaseRequest(string $url, string $method = 'GET', $data = null): array {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    if ($data !== null) {
        $json = json_encode($data);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $json);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json', 'Content-Length: ' . strlen($json)]);
    }
    $result = curl_exec($ch);
    $code   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'body' => json_decode($result, true)];
}

// ─── Telegram Upload Helper ───────────────────────────────────────────────────
function uploadToTelegram(string $bot_token, string $chat_id, $file, string $type, string $caption): array {
    $endpoint  = $type === 'photo' ? 'sendPhoto' : 'sendVideo';
    $fieldName = $type === 'photo' ? 'photo' : 'video';
    $ch = curl_init("https://api.telegram.org/bot$bot_token/$endpoint");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, [
        'chat_id'  => $chat_id,
        $fieldName => new CURLFile($file['tmp_name'], $file['type'], $file['name']),
        'caption'  => $caption,
    ]);
    $res = json_decode(curl_exec($ch), true);
    curl_close($ch);
    if (!$res || !$res['ok']) return ['url' => '', 'file_id' => ''];
    $file_id = $type === 'photo' ? end($res['result']['photo'])['file_id'] : $res['result']['video']['file_id'];
    $gf = json_decode(file_get_contents("https://api.telegram.org/bot$bot_token/getFile?file_id=$file_id"), true);
    if ($gf && $gf['ok']) {
        return [
            'url' => "https://api.telegram.org/file/bot$bot_token/" . $gf['result']['file_path'],
            'file_id' => $file_id
        ];
    }
    return ['url' => '', 'file_id' => $file_id];
}

// ─── Handle POST Actions ──────────────────────────────────────────────────────
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $action = $_POST['action'] ?? 'publish_short';

    // ── 1. Publish Short ──────────────────────────────────────────────────────
    if ($action === 'publish_short') {
        $title = trim($_POST['title'] ?? 'فيديو جديد');
        $video_url = "";

        if (isset($_FILES['video_file']) && $_FILES['video_file']['error'] != UPLOAD_ERR_NO_FILE) {
            if ($_FILES['video_file']['error'] == UPLOAD_ERR_OK) {
                // Determine if it is a photo or video based on MIME type
                $is_photo  = strpos($_FILES['video_file']['type'], 'image') !== false;
                $uploadResult = uploadToTelegram($bot_token, $chat_id, $_FILES['video_file'], $is_photo ? 'photo' : 'video', $title);
                $video_url = $uploadResult['url'] ?? '';
                $tg_file_id = $uploadResult['file_id'] ?? '';
                
                if (empty($video_url)) { 
                    $message = "❌ فشل رفع الملف إلى تيليجرام. قد يكون حجم الملف كبيراً جداً (أقصى حد للبوت العادي 20MB للصور والفيديو)."; 
                    $msgType = "error"; 
                }
            } else {
                $errCode = $_FILES['video_file']['error'];
                // Handle common PHP upload errors
                if ($errCode == UPLOAD_ERR_INI_SIZE || $errCode == UPLOAD_ERR_FORM_SIZE) {
                    $message = "❌ فشل الرفع: حجم الملف يتجاوز الحد المسموح به في إعدادات السيرفر.";
                } else {
                    $message = "❌ فشل أثناء رفع الملف (كود الخطأ: $errCode).";
                }
                $msgType = "error";
            }
        } elseif (!empty($_POST['link_url'])) {
            $video_url = trim($_POST['link_url']);
        }

        if (!empty($video_url)) {
            $data = [
                'title'        => $title,
                'video_url'    => $video_url,
                'tg_file_id'   => $tg_file_id ?? '',
                'likes'        => rand(50, 500),
                'comments'     => rand(10, 50),
                'account_name' => 'عالمنا',
                'created_at'   => date('Y-m-d H:i:s'),
            ];
            $res = firebaseRequest("$firebase_base/Main/Shorts.json", 'POST', $data);
            $message = ($res['code'] >= 200 && $res['code'] < 300)
                ? "✅ تم نشر المقطع بنجاح! سيظهر في التطبيق فوراً."
                : "❌ خطأ في Firebase (كود: {$res['code']})";
            if (strpos($message, '❌') !== false) $msgType = "error";
        } elseif (empty($message)) {
            $message = "⚠️ يرجى اختيار ملف أو وضع رابط."; $msgType = "warning";
        }
    }

    // ── 2. Toggle News ────────────────────────────────────────────────────────
    elseif ($action === 'toggle_news') {
        $enabled = ($_POST['news_enabled'] ?? 'false') === 'true';
        $res = firebaseRequest("$firebase_base/config/newsEnabled.json", 'PUT', $enabled);
        $message = ($res['code'] >= 200 && $res['code'] < 300)
            ? "✅ تم " . ($enabled ? 'تفعيل' : 'إيقاف') . " الأخبار بنجاح!"
            : "❌ خطأ: {$res['code']}";
        if (strpos($message, '❌') !== false) $msgType = "error";
    }

    // ── 3. Add/Update Ad ──────────────────────────────────────────────────────
    elseif ($action === 'add_ad') {
        $ad_img   = trim($_POST['ad_image_url'] ?? '');
        $ad_text  = trim($_POST['ad_text'] ?? '');
        $ad_btn   = trim($_POST['ad_button_text'] ?? 'اضغط هنا');
        $ad_link  = trim($_POST['ad_link'] ?? '');

        if (empty($ad_img) || empty($ad_text) || empty($ad_link)) {
            $message = "⚠️ يرجى ملء جميع حقول الإعلان."; $msgType = "warning";
        } else {
            $ad_data = [
                'image'       => $ad_img,
                'text'        => $ad_text,
                'button_text' => $ad_btn,
                'link'        => $ad_link,
                'enabled'     => true,
                'created_at'  => date('Y-m-d H:i:s'),
            ];
            $res = firebaseRequest("$firebase_base/config/ads.json", 'POST', $ad_data);
            $message = ($res['code'] >= 200 && $res['code'] < 300)
                ? "✅ تم إضافة الإعلان بنجاح!"
                : "❌ خطأ في Firebase: {$res['code']}";
            if (strpos($message, '❌') !== false) $msgType = "error";
        }
    }

    // ── 4. Add Slider Item ────────────────────────────────────────────────────
    elseif ($action === 'add_slider') {
        $sl_title = trim($_POST['slider_title'] ?? '');
        $sl_img   = trim($_POST['slider_image'] ?? '');
        $sl_desc  = trim($_POST['slider_desc'] ?? '');

        if (empty($sl_title) || empty($sl_img)) {
            $message = "⚠️ يرجى إدخال العنوان والصورة للسلايدر."; $msgType = "warning";
        } else {
            $slider_data = [
                'title'       => $sl_title,
                'image'       => $sl_img,
                'description' => $sl_desc,
                'type'        => 'sports_news',
                'created_at'  => date('Y-m-d H:i:s'),
            ];
            $res = firebaseRequest("$firebase_base/config/sliderItems.json", 'POST', $slider_data);
            $message = ($res['code'] >= 200 && $res['code'] < 300)
                ? "✅ تم إضافة العنصر إلى السلايدر بنجاح!"
                : "❌ خطأ: {$res['code']}";
            if (strpos($message, '❌') !== false) $msgType = "error";
        }
    }
}

// ─── Fetch Current Config ─────────────────────────────────────────────────────
$configRes   = firebaseRequest("$firebase_base/config.json");
$config      = $configRes['body'] ?? [];
$newsEnabled = $config['newsEnabled'] ?? true;
$ads         = $config['ads'] ?? [];
$sliderItems = $config['sliderItems'] ?? [];
$shortsRes   = firebaseRequest("$firebase_base/Main/Shorts.json");
$shorts      = $shortsRes['body'] ?? [];
$totalShorts = is_array($shorts) ? count($shorts) : 0;
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>لوحة عالمنا - Admin Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #0a0a12;
            --surface: #12121e;
            --surface2: #1a1a2e;
            --accent: #4c46e8;
            --accent2: #ff0050;
            --success: #1b5e20;
            --error: #b71c1c;
            --warning: #e65100;
            --text: #ffffff;
            --text2: #a0a0b0;
            --border: rgba(255,255,255,0.08);
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Tajawal', sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
        }
        /* Sidebar */
        .sidebar {
            width: 240px;
            background: var(--surface);
            border-left: 1px solid var(--border);
            position: fixed;
            top: 0; right: 0; bottom: 0;
            display: flex;
            flex-direction: column;
            padding: 24px 0;
            z-index: 100;
        }
        .sidebar-logo {
            text-align: center;
            padding: 0 20px 24px;
            border-bottom: 1px solid var(--border);
        }
        .sidebar-logo h1 {
            font-size: 22px;
            font-weight: 800;
            background: linear-gradient(135deg, var(--accent), var(--accent2));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .sidebar-logo span { font-size: 12px; color: var(--text2); }
        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 14px 20px;
            cursor: pointer;
            color: var(--text2);
            font-size: 15px;
            transition: all 0.2s;
            border-right: 3px solid transparent;
        }
        .nav-item:hover, .nav-item.active {
            color: var(--text);
            background: var(--surface2);
            border-right-color: var(--accent);
        }
        .nav-item .icon { font-size: 20px; }
        /* Main content */
        .main {
            margin-right: 240px;
            padding: 30px;
            min-height: 100vh;
        }
        .page-header {
            margin-bottom: 28px;
        }
        .page-header h2 {
            font-size: 26px;
            font-weight: 800;
            margin-bottom: 6px;
        }
        .page-header p { color: var(--text2); font-size: 14px; }
        /* Stats */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }
        .stat-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 20px;
            text-align: center;
        }
        .stat-card .value { font-size: 32px; font-weight: 800; color: var(--accent); }
        .stat-card .label { font-size: 13px; color: var(--text2); margin-top: 6px; }
        /* Cards */
        .card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 20px;
        }
        .card h3 {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        /* Inputs */
        .form-group { margin-bottom: 16px; }
        .form-group label { display: block; font-size: 13px; color: var(--text2); margin-bottom: 8px; }
        input[type="text"], input[type="url"], textarea, select {
            width: 100%;
            padding: 12px 16px;
            background: var(--surface2);
            border: 1px solid var(--border);
            border-radius: 10px;
            color: var(--text);
            font-family: 'Tajawal', sans-serif;
            font-size: 15px;
            transition: border-color 0.2s;
        }
        input:focus, textarea:focus { outline: none; border-color: var(--accent); }
        input[type="file"] {
            width: 100%;
            padding: 10px;
            background: var(--surface2);
            border: 2px dashed var(--border);
            border-radius: 10px;
            color: var(--text2);
            cursor: pointer;
        }
        textarea { min-height: 80px; resize: vertical; }
        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-family: 'Tajawal', sans-serif;
            font-size: 15px;
            font-weight: 700;
            transition: all 0.2s;
        }
        .btn-primary { background: var(--accent); color: white; }
        .btn-primary:hover { background: #3d38d0; transform: translateY(-1px); }
        .btn-danger { background: var(--accent2); color: white; }
        .btn-danger:hover { background: #cc003f; }
        .btn-success { background: #2e7d32; color: white; }
        .btn-outline {
            background: transparent;
            border: 1px solid var(--border);
            color: var(--text2);
        }
        .btn-outline:hover { border-color: var(--accent); color: var(--text); }
        /* Toggle switch */
        .toggle-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 0;
            border-bottom: 1px solid var(--border);
        }
        .toggle-row:last-child { border-bottom: none; }
        .toggle-label { font-size: 15px; font-weight: 600; }
        .toggle-desc { font-size: 13px; color: var(--text2); }
        .switch { position: relative; display: inline-block; width: 52px; height: 28px; }
        .switch input { opacity: 0; width: 0; height: 0; }
        .slider-toggle {
            position: absolute;
            cursor: pointer;
            inset: 0;
            background: #333;
            border-radius: 28px;
            transition: 0.3s;
        }
        .slider-toggle:before {
            content: '';
            position: absolute;
            width: 20px; height: 20px;
            right: 4px; bottom: 4px;
            background: white;
            border-radius: 50%;
            transition: 0.3s;
        }
        input:checked + .slider-toggle { background: var(--accent); }
        input:checked + .slider-toggle:before { transform: translateX(-24px); }
        /* Alert */
        .alert {
            padding: 14px 20px;
            border-radius: 12px;
            margin-bottom: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
            animation: slideIn 0.3s ease;
        }
        @keyframes slideIn { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }
        .alert-success { background: #1b5e20; border: 1px solid #2e7d32; }
        .alert-error   { background: #b71c1c; border: 1px solid #d32f2f; }
        .alert-warning { background: #e65100; border: 1px solid #f57c00; }
        /* Table */
        .table { width: 100%; border-collapse: collapse; }
        .table th, .table td {
            padding: 12px 16px;
            text-align: right;
            border-bottom: 1px solid var(--border);
            font-size: 14px;
        }
        .table th { color: var(--text2); font-weight: 600; background: var(--surface2); }
        .table tr:hover td { background: var(--surface2); }
        /* Tabs */
        .tabs { display: flex; gap: 4px; margin-bottom: 24px; border-bottom: 2px solid var(--border); }
        .tab {
            padding: 12px 24px;
            cursor: pointer;
            font-size: 15px;
            font-weight: 600;
            color: var(--text2);
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            transition: all 0.2s;
        }
        .tab.active, .tab:hover { color: var(--accent); border-bottom-color: var(--accent); }
        /* Sections */
        .section { display: none; }
        .section.active { display: block; }
        /* Grid 2 col */
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        @media (max-width: 768px) { .grid-2 { grid-template-columns: 1fr; } }
        /* Badge */
        .badge {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .badge-on  { background: rgba(46,125,50,0.2); color: #66bb6a; border: 1px solid #2e7d32; }
        .badge-off { background: rgba(183,28,28,0.2); color: #ef9a9a; border: 1px solid #b71c1c; }
    </style>
</head>
<body>

<!-- Sidebar -->
<div class="sidebar">
    <div class="sidebar-logo">
        <h1>⚽ عالمنا</h1>
        <span>لوحة التحكم الإدارية</span>
    </div>
    <div style="padding: 16px 0;">
        <div class="nav-item active" onclick="showSection('shorts')">
            <span class="icon">🎬</span> نشر مقاطع
        </div>
        <div class="nav-item" onclick="showSection('news')">
            <span class="icon">📰</span> تحكم الأخبار
        </div>
        <div class="nav-item" onclick="showSection('ads')">
            <span class="icon">📢</span> الإعلانات
        </div>
        <div class="nav-item" onclick="showSection('slider')">
            <span class="icon">🖼️</span> السلايدر
        </div>
        <div class="nav-item" onclick="showSection('overview')">
            <span class="icon">📊</span> نظرة عامة
        </div>
    </div>
</div>

<!-- Main Content -->
<div class="main">
    <!-- Alert Message -->
    <?php if (!empty($message)): ?>
        <div class="alert alert-<?= $msgType ?>">
            <?= htmlspecialchars($message) ?>
        </div>
    <?php endif; ?>

    <!-- ══ SECTION: Overview ══════════════════════════════════════════════ -->
    <div id="section-overview" class="section">
        <div class="page-header">
            <h2>📊 نظرة عامة</h2>
            <p>إحصائيات التطبيق والمحتوى المنشور</p>
        </div>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="value"><?= $totalShorts ?></div>
                <div class="label">🎬 مقاطع منشورة</div>
            </div>
            <div class="stat-card">
                <div class="value"><?= is_array($ads) ? count($ads) : 0 ?></div>
                <div class="label">📢 إعلانات نشطة</div>
            </div>
            <div class="stat-card">
                <div class="value"><?= is_array($sliderItems) ? count($sliderItems) : 0 ?></div>
                <div class="label">🖼️ عناصر السلايدر</div>
            </div>
            <div class="stat-card">
                <div class="value"><?= $newsEnabled ? '🟢' : '🔴' ?></div>
                <div class="label">📰 حالة الأخبار</div>
            </div>
        </div>
    </div>

    <!-- ══ SECTION: Publish Short ═════════════════════════════════════════ -->
    <div id="section-shorts" class="section active">
        <div class="page-header">
            <h2>🎬 نشر مقطع جديد</h2>
            <p>رفع فيديو أو صورة إلى قسم المقاطع القصيرة</p>
        </div>
        <div class="grid-2">
            <form method="POST" enctype="multipart/form-data">
                <input type="hidden" name="action" value="publish_short">
                <div class="card">
                    <h3>📤 رفع محتوى</h3>
                    <div class="form-group">
                        <label>عنوان المقطع</label>
                        <input type="text" name="title" placeholder="أدخل عنواناً جذاباً..." required>
                    </div>
                    <div class="form-group">
                        <label>📁 رفع من الجهاز (تخزين تيليجرام)</label>
                        <input type="file" name="video_file" accept="video/*,image/*">
                    </div>
                    <div class="form-group">
                        <label>🔗 أو رابط مباشر</label>
                        <input type="url" name="link_url" placeholder="https://example.com/video.mp4">
                    </div>
                    <button type="submit" class="btn btn-primary">
                        🚀 نشر الآن
                    </button>
                </div>
            </form>

            <!-- Latest Shorts -->
            <div class="card">
                <h3>📋 آخر المنشورات (<?= $totalShorts ?>)</h3>
                <?php if (is_array($shorts) && !empty($shorts)): ?>
                    <div style="max-height: 300px; overflow-y: auto;">
                        <table class="table">
                            <thead><tr><th>العنوان</th><th>👍</th><th>💬</th></tr></thead>
                            <tbody>
                            <?php foreach (array_slice(array_reverse($shorts), 0, 10) as $key => $s): ?>
                                <tr>
                                    <td><?= htmlspecialchars(mb_substr($s['title'] ?? '-', 0, 30)) ?></td>
                                    <td><?= $s['likes'] ?? 0 ?></td>
                                    <td><?= $s['comments'] ?? 0 ?></td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php else: ?>
                    <p style="color: var(--text2); text-align: center; padding: 30px;">لا توجد مقاطع بعد</p>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- ══ SECTION: News Control ══════════════════════════════════════════ -->
    <div id="section-news" class="section">
        <div class="page-header">
            <h2>📰 تحكم الأخبار الرياضية</h2>
            <p>تفعيل أو إيقاف عرض الأخبار في السلايدر الرئيسي</p>
        </div>
        <div class="card">
            <h3>⚙️ إعدادات الأخبار</h3>
            <div class="toggle-row">
                <div>
                    <div class="toggle-label">📰 الأخبار الرياضية في السلايدر</div>
                    <div class="toggle-desc">عند التفعيل، يعرض السلايدر أحدث الأخبار الرياضية تلقائياً</div>
                </div>
                <div style="display: flex; align-items: center; gap: 12px;">
                    <span class="badge <?= $newsEnabled ? 'badge-on' : 'badge-off' ?>">
                        <?= $newsEnabled ? 'مفعّل' : 'موقوف' ?>
                    </span>
                    <form method="POST">
                        <input type="hidden" name="action" value="toggle_news">
                        <input type="hidden" name="news_enabled" value="<?= $newsEnabled ? 'false' : 'true' ?>">
                        <button type="submit" class="btn <?= $newsEnabled ? 'btn-danger' : 'btn-success' ?>">
                            <?= $newsEnabled ? '⏸ إيقاف الأخبار' : '▶ تفعيل الأخبار' ?>
                        </button>
                    </form>
                </div>
            </div>
            <div class="toggle-row">
                <div>
                    <div class="toggle-label">🏆 نوع الأخبار</div>
                    <div class="toggle-desc">رياضية - يستخدم موجز Sky Sports و BBC Sport</div>
                </div>
                <span class="badge badge-on">رياضية ✓</span>
            </div>
        </div>
    </div>

    <!-- ══ SECTION: Ads ════════════════════════════════════════════════════ -->
    <div id="section-ads" class="section">
        <div class="page-header">
            <h2>📢 إدارة الإعلانات</h2>
            <p>إضافة إعلانات تُعرض للمستخدمين داخل التطبيق</p>
        </div>
        <div class="grid-2">
            <form method="POST">
                <input type="hidden" name="action" value="add_ad">
                <div class="card">
                    <h3>➕ إضافة إعلان جديد</h3>
                    <div class="form-group">
                        <label>🖼️ رابط صورة الإعلان</label>
                        <input type="url" name="ad_image_url" placeholder="https://example.com/ad.jpg" required>
                    </div>
                    <div class="form-group">
                        <label>📝 نص الإعلان</label>
                        <textarea name="ad_text" placeholder="اكتب نص الإعلان هنا..." required></textarea>
                    </div>
                    <div class="form-group">
                        <label>🔘 نص الزر</label>
                        <input type="text" name="ad_button_text" value="اضغط هنا" required>
                    </div>
                    <div class="form-group">
                        <label>🔗 رابط الزر (عند الضغط)</label>
                        <input type="url" name="ad_link" placeholder="https://example.com" required>
                    </div>
                    <button type="submit" class="btn btn-primary">💾 حفظ الإعلان</button>
                </div>
            </form>

            <!-- Existing Ads -->
            <div class="card">
                <h3>📋 الإعلانات الحالية (<?= is_array($ads) ? count($ads) : 0 ?>)</h3>
                <?php if (is_array($ads) && !empty($ads)): ?>
                    <?php foreach ($ads as $key => $ad): ?>
                        <div style="border: 1px solid var(--border); border-radius: 10px; padding: 12px; margin-bottom: 12px;">
                            <div style="font-weight: 700; margin-bottom: 4px;"><?= htmlspecialchars(mb_substr($ad['text'] ?? '-', 0, 50)) ?></div>
                            <div style="font-size: 12px; color: var(--text2);">زر: <?= htmlspecialchars($ad['button_text'] ?? '-') ?></div>
                            <div style="font-size: 12px; color: var(--accent); margin-top: 4px; word-break: break-all;"><?= htmlspecialchars(mb_substr($ad['link'] ?? '-', 0, 50)) ?></div>
                        </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <p style="color: var(--text2); text-align: center; padding: 30px;">لا توجد إعلانات بعد</p>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- ══ SECTION: Slider ════════════════════════════════════════════════ -->
    <div id="section-slider" class="section">
        <div class="page-header">
            <h2>🖼️ إدارة السلايدر</h2>
            <p>إضافة عناصر مخصصة للسلايدر الرئيسي (تظهر بدلاً من الأخبار التلقائية)</p>
        </div>
        <div class="grid-2">
            <form method="POST">
                <input type="hidden" name="action" value="add_slider">
                <div class="card">
                    <h3>➕ إضافة عنصر للسلايدر</h3>
                    <div class="form-group">
                        <label>📌 العنوان الرئيسي</label>
                        <input type="text" name="slider_title" placeholder="عنوان الخبر الرياضي..." required>
                    </div>
                    <div class="form-group">
                        <label>🖼️ رابط الصورة (عرض كامل مناسب)</label>
                        <input type="url" name="slider_image" placeholder="https://example.com/sports.jpg" required>
                        <small style="color: var(--text2); font-size: 11px; margin-top: 4px; display: block;">يُنصح باستخدام صور بعرض 1200px على الأقل</small>
                    </div>
                    <div class="form-group">
                        <label>📄 وصف مختصر (اختياري)</label>
                        <textarea name="slider_desc" placeholder="وصف مختصر للخبر..."></textarea>
                    </div>
                    <button type="submit" class="btn btn-primary">💾 إضافة للسلايدر</button>
                </div>
            </form>

            <!-- Slider Items -->
            <div class="card">
                <h3>🖼️ عناصر السلايدر الحالية (<?= is_array($sliderItems) ? count($sliderItems) : 0 ?>)</h3>
                <?php if (is_array($sliderItems) && !empty($sliderItems)): ?>
                    <?php foreach ($sliderItems as $key => $item): ?>
                        <div style="display: flex; gap: 12px; border: 1px solid var(--border); border-radius: 10px; padding: 12px; margin-bottom: 12px;">
                            <img src="<?= htmlspecialchars($item['image'] ?? '') ?>" style="width: 80px; height: 50px; object-fit: cover; border-radius: 6px;" onerror="this.style.display='none'">
                            <div>
                                <div style="font-weight: 700; font-size: 13px;"><?= htmlspecialchars(mb_substr($item['title'] ?? '-', 0, 40)) ?></div>
                                <div style="font-size: 11px; color: var(--text2); margin-top: 4px;"><?= htmlspecialchars(mb_substr($item['description'] ?? '-', 0, 50)) ?></div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <p style="color: var(--text2); text-align: center; padding: 30px;">لا توجد عناصر محددة - سيعرض الأخبار التلقائية</p>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<script>
function showSection(name) {
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.getElementById('section-' + name).classList.add('active');
    event.currentTarget.classList.add('active');
}
</script>
</body>
</html>
