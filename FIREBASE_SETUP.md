# Firebase Cloud Messaging Setup Guide

This guide will help you set up Firebase Cloud Messaging (FCM) for push notifications in the Agribusiness News app.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `Agribusiness News`
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter your Bundle ID: `com.agribusinessmedia.AgribusinessNewsApp` (or your actual bundle ID)
3. Enter App nickname: `Agribusiness News`
4. Download `GoogleService-Info.plist`
5. **Important**: Add `GoogleService-Info.plist` to your Xcode project:
   - Drag the file into Xcode under `AgribusinessNewsApp` folder
   - Make sure "Copy items if needed" is checked
   - Ensure it's added to the target

## Step 3: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the Firebase iOS SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Select version: **Up to Next Major Version** from `11.0.0`
4. Click "Add Package"
5. Select these packages to add:
   - **FirebaseMessaging**
   - **FirebaseAnalytics** (optional)
6. Click "Add Package"

## Step 4: Configure APNs in Firebase

### Generate APNs Key (Recommended Method)

1. Go to [Apple Developer Account](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles → Keys**
3. Click the **+** button to create a new key
4. Enter Key Name: `Agribusiness News Push Key`
5. Check **Apple Push Notifications service (APNs)**
6. Click **Continue**, then **Register**
7. **Download the .p8 file** (you can only download once!)
8. Note the **Key ID** shown on the page
9. Note your **Team ID** (found in Membership section)

### Upload APNs Key to Firebase

1. In Firebase Console, go to **Project Settings → Cloud Messaging**
2. Under "Apple app configuration", click "Upload" next to APNs Authentication Key
3. Upload the .p8 file
4. Enter your Key ID and Team ID
5. Click "Upload"

## Step 5: Enable Push Notifications in Xcode

1. Select your project in Xcode
2. Select the **AgribusinessNewsApp** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and check:
   - Background fetch
   - Remote notifications

## Step 6: WordPress Integration

To send notifications when new content is published on WordPress, you need to set up a webhook or use a WordPress plugin.

### Option A: Using WordPress Plugin

Install the **FCM Push Notifications** or **OneSignal** plugin on your WordPress site.

### Option B: Custom WordPress Integration

Add this code to your WordPress theme's `functions.php` or create a custom plugin:

```php
<?php
// Firebase Cloud Messaging for WordPress
// Add to functions.php or create a plugin

define('FCM_SERVER_KEY', 'YOUR_FCM_SERVER_KEY_HERE');

// Send notification when post is published
add_action('publish_post', 'send_fcm_notification_on_publish', 10, 2);

function send_fcm_notification_on_publish($post_id, $post) {
    // Only for new posts, not updates
    if (wp_is_post_revision($post_id)) {
        return;
    }
    
    // Get post details
    $title = $post->post_title;
    $excerpt = wp_trim_words($post->post_excerpt ?: $post->post_content, 20);
    
    // Get category
    $categories = get_the_category($post_id);
    $category = !empty($categories) ? $categories[0]->name : 'News';
    
    // Get featured image
    $image_url = get_the_post_thumbnail_url($post_id, 'medium');
    
    // Prepare FCM message
    $message = array(
        'to' => '/topics/new_articles', // Send to topic subscribers
        'notification' => array(
            'title' => '📰 ' . $category,
            'body' => $title,
            'sound' => 'default',
            'badge' => '1'
        ),
        'data' => array(
            'type' => 'article',
            'post_id' => strval($post_id),
            'url' => get_permalink($post_id),
            'image' => $image_url ?: ''
        )
    );
    
    send_fcm_message($message);
}

// Send notification when new media (magazine) is uploaded
add_action('add_attachment', 'send_fcm_notification_on_magazine', 10, 1);

function send_fcm_notification_on_magazine($attachment_id) {
    $attachment = get_post($attachment_id);
    $mime_type = get_post_mime_type($attachment_id);
    
    // Only for PDF files with "ISSUE" in title
    if ($mime_type !== 'application/pdf') {
        return;
    }
    
    $title = strtoupper($attachment->post_title);
    if (strpos($title, 'ISSUE') === false) {
        return;
    }
    
    // Extract issue number
    preg_match('/ISSUE[\s-]*(\d+)/', $title, $matches);
    $issue_number = isset($matches[1]) ? 'Issue ' . $matches[1] : 'New Issue';
    
    $message = array(
        'to' => '/topics/new_magazines',
        'notification' => array(
            'title' => '📖 New Magazine Available',
            'body' => $issue_number . ' is now available!',
            'sound' => 'default',
            'badge' => '1'
        ),
        'data' => array(
            'type' => 'magazine',
            'attachment_id' => strval($attachment_id),
            'url' => wp_get_attachment_url($attachment_id)
        )
    );
    
    send_fcm_message($message);
}

function send_fcm_message($message) {
    $headers = array(
        'Authorization: key=' . FCM_SERVER_KEY,
        'Content-Type: application/json'
    );
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    
    $result = curl_exec($ch);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        error_log('FCM Error: ' . $error);
    } else {
        error_log('FCM Result: ' . $result);
    }
    
    return $result;
}
?>
```

### Getting Your FCM Server Key

1. Go to Firebase Console → Project Settings
2. Go to **Cloud Messaging** tab
3. If you see "Cloud Messaging API (Legacy)" is disabled, enable it
4. Copy the **Server key**
5. Replace `YOUR_FCM_SERVER_KEY_HERE` in the WordPress code

## Step 7: Testing

1. Build and run the app on a **physical device** (simulators don't support push notifications)
2. Allow notifications when prompted
3. Publish a test post on WordPress
4. You should receive a push notification!

## Troubleshooting

### Notifications not received?

1. Ensure the device is registered (check Xcode console for FCM token)
2. Verify APNs key is properly uploaded to Firebase
3. Check WordPress error logs for FCM errors
4. Make sure app is properly subscribed to topics

### FCM Token not generated?

1. Ensure `GoogleService-Info.plist` is in the project
2. Check that Push Notifications capability is added
3. Verify Bundle ID matches Firebase configuration

## Topics Used

The app subscribes to these FCM topics:
- `new_articles` - For new article notifications
- `new_videos` - For new video notifications  
- `new_magazines` - For new magazine notifications
- `all_users` - For announcements to all users
