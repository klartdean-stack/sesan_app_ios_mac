const {onDocumentUpdated, onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");


if (admin.apps.length === 0) {
    admin.initializeApp();
}


// ... បន្តទៅមុខទៀត


// 🔔 មុខងារជូនដំណឹងទៅ Seller ពេលមានការបញ្ជាក់ការកម្ម៉ង់ (Status: confirmed)
exports.notifySellerOnConfirmedOrder = onDocumentUpdated({
    document: "orders/{orderId}",
    region: "asia-southeast1"
}, async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const sellerId = afterData.seller_id; // 👈 មេឆែកមើលក្នុង DB ថាឈ្មោះ field ហ្នឹងមែនអត់


    // 🎯 ឆែកថា Status ទើបតែប្តូរមកជា confirmed មែនអត់
    if (beforeData.status !== "confirmed" && afterData.status === "confirmed") {
        if (!sellerId) return null;


        try {
            // ១. ទៅយក fcmToken របស់ Seller ពី Collection users
            const sellerDoc = await admin.firestore().collection("users").doc(sellerId).get();
            const token = sellerDoc.data()?.fcmToken;


            // ជួសត្រង់ចំណុចដែលផ្ញើសារ (Line 33-40)
            if (token) {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: "មានការកម្ម៉ង់ថ្មី! 🚀",
                        body: "មានអតិថិជនកម្ម៉ង់ទំនិញថ្មី!",
                    },
                    // 🚀 ត្រូវថែមផ្នែកខាងក្រោមនេះ ដើម្បីបំបាត់ Logo Flutter
                    android: {
                        priority: "high",
                        notification: {
                            channelId: "high_importance_channel",
                            icon: 'ic_stat_sesan',
                            color: '#FF4500',
                            sound: "default",
                            clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        }
                    }
                });
                console.log("Notification sent to seller:", sellerId);
            }
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    }
    return null;
});


// 🔔 ២. ជូនដំណឹងទៅ Customer ពេល Status ប្រែប្រួល
exports.handleOrderTrackingNotifications = onDocumentUpdated({
    document: "orders/{orderId}",
    region: "asia-southeast1"
}, async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const customerId = afterData.customer_id;


    if (!customerId) return null;


    try {
        const customerDoc = await admin.firestore().collection("users").doc(customerId).get();
        const token = customerDoc.data()?.fcmToken;


        if (token) {
            let title = "";
            let body = "";


            if (beforeData.status !== "packing" && afterData.status === "packing") {
                title = "ការកម្ម៉ង់ត្រូវបានទទួល!";
                body = "ការកម្ម៉ង់របស់បងត្រូវបានទទួលនិងកំពុងវិចខ្ចប់!";
            } else if (beforeData.status !== "on_delivery" && afterData.status === "on_delivery") {
                title = "ទំនិញកំពុងដឹកជញ្ជូន!";
                body = "ទំនិញបងបានដាក់ផ្ញើនិងដឹកជញ្ជូន!";
            } else if (beforeData.status !== "delivered" && afterData.status === "delivered") {
                title = "ទំនិញមកដល់ហើយ!";
                body = "ទំនិញបងបានមកដល់ទីតាំងហើយ";
            }


            if (title !== "") {
                await admin.messaging().send({
                    notification: { title, body },
                    android: {
            priority: "high",
            notification: {
                channelId: "order_channel",
                icon: 'ic_stat_sesan',
                color: '#FF4500',
                sound: "default",
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
            }
        },
                    token: token
                });
            }
        }
    } catch (error) {
        console.error("Error Notification:", error);
    }
    return null;
});


// 🔐 ៣. មុខងារដកលុយដោយផ្ទៀងផ្ទាត់ PIN (Secure Withdraw)
exports.secureWithdraw = onCall({ region: "asia-southeast1" }, async (request) => {
    // 🛡️ ឆែក Auth សិនដើម្បីការពារ Error uid
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'សូមចូលគណនីជាមុនសិន!');
    }


    const uid = request.auth.uid;
    const amount = request.data.amount;
    const pin = request.data.pin;


    const userRef = admin.firestore().collection('users').doc(uid);


    try {
        return await admin.firestore().runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) throw new HttpsError('not-found', 'រកមិនឃើញអ្នកប្រើប្រាស់!');


            const userData = userDoc.data();

            // 🎯 ផ្ទៀងផ្ទាត់ PIN (សំខាន់បំផុតដើម្បីកុំឱ្យរំលង)
            if (!pin || String(pin) !== String(userData.password)) {
                throw new HttpsError('permission-denied', 'លេខសម្ងាត់មិនត្រឹមត្រូវ!');
            }


            // ឆែកឈ្មោះ Field ឱ្យត្រូវ (ក្នុង DB មេឈ្មោះ 'balance' ឬ 'wallet_balance'?)
            const currentBalance = userData.balance || 0;
            if (amount <= 0 || amount > currentBalance) {
                throw new HttpsError('invalid-argument', 'សមតុល្យមិនគ្រប់គ្រាន់!');
            }// ១. កាត់លុយចេញ
            transaction.update(userRef, {
                balance: admin.firestore.FieldValue.increment(-amount),
                total_withdraw: admin.firestore.FieldValue.increment(amount)
            });


            // ២. បង្កើតសំណើដកប្រាក់
            const withdrawRef = admin.firestore().collection('withdraw_requests').doc();
            transaction.set(withdrawRef, {
                seller_id: uid,
                amount: amount,
                status: 'pending',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });


            return { success: true, message: "សំណើដកប្រាក់ជោគជ័យ!" };
        });
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        throw new HttpsError('internal', error.message);
    }
});
// 🎯 ផាសបន្តពីក្រោមជួរទី 138 មកមេ
exports.sendSellerNotification = onCall(async (request) => {
    const { sellerId, title, body } = request.data;


    try {
        // ១. ទៅទាញយក fcm_token របស់អ្នកលក់ពី Firestore
        const userDoc = await admin.firestore().collection('users').doc(sellerId).get();
        const userData = userDoc.data();


        if (!userData || !userData.fcmToken) {
            console.log("រកមិនឃើញ Token របស់អ្នកលក់ឡើយ");
            return { success: false, error: "No token found" };
        }


        // ២. រៀបចំសារបាញ់ទៅកាន់ Messaging
        const message = {
            notification: {
                title: title,
                body: body
            },
                android: {
            priority: "high",
            notification: {
                channelId: "high_importance_channel",
                icon: 'ic_stat_sesan',
                color: '#FF4500',
                sound: "default",
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
            }
        },
            token: userData.fcmToken,
        };


        const response = await admin.messaging().send(message);
        console.log("Notification បានផ្ញើជោគជ័យ:", response);
        return { success: true };


    } catch (error) {
        console.error("កំហុសក្នុងការផ្ញើ Noti:", error);
        throw new HttpsError("internal", error.message);
    }
});


// កូដសម្រាប់តេស្ត (ដាក់ពីក្រោម exports.scheduledWalletSettlement ក៏បាន)
exports.testWalletNow = onDocumentUpdated({
    document: "orders/{orderId}",
    region: "asia-southeast1"
}, async (event) => {
    const db = admin.firestore();
    const orderData = event.data.after.data();

    console.log("--- ចាប់ផ្ដើមតេស្ត Logic ៥ ថ្ងៃ ---");

    const now = new Date();
    // ឆែកមើលថាមាន packing_date អត់ បើអត់ទេឱ្យវាស្មើម៉ោងឥឡូវ
    const packingDate = orderData.packing_date ? orderData.packing_date.toDate() : new Date();

    console.log("ម៉ោងឥឡូវ (Server):", now.toISOString());
    console.log("ម៉ោងក្នុងបុង (Packing Date):", packingDate.toISOString());


    const diffInMs = now.getTime() - packingDate.getTime();
    const fiveDaysInMs = 5 * 24 * 60 * 60 * 1000;


    if (diffInMs >= fiveDaysInMs && orderData.is_settled === false) {
        console.log("✅ គ្រប់លក្ខខណ្ឌ ៥ ថ្ងៃ! កំពុងបូកលុយ...");
        const userRef = db.collection("users").doc(orderData.seller_id);
        await userRef.set({
            "wallet_balance": admin.firestore.FieldValue.increment(-orderData.seller_earnings),
            "available_balance": admin.firestore.FieldValue.increment(orderData.seller_earnings)
        }, { merge: true });

        // ចំណាំថាទូទាត់រួច
        await event.data.after.ref.update({ is_settled: true });
    } else {
        console.log("❌ មិនទាន់គ្រប់ ៥ ថ្ងៃ ឬ ទូទាត់រួចហើយ");
    }
});


exports.notifyOnNewChatMessage = onDocumentCreated({
    document: "chats/{chatDocId}",
    region: "asia-southeast1"
}, async (event) => {
    const data = event.data.data();
    const receiverId = data.receiver;
    const senderId = data.sender;

    if (!receiverId || senderId === receiverId) {
        console.log("អ្នកផ្ញើ និងអ្នកទទួលជាមនុស្សតែម្នាក់។ មិនផ្ញើ Noti ឡើយ។");
        return null;
    }

    try {
        // ✅ ទាញឈ្មោះអ្នកផ្ញើពី Firestore
        const senderDoc = await admin.firestore()
            .collection("users")
            .doc(senderId)
            .get();

        const senderName = senderDoc.exists
            ? (senderDoc.data().name || 'អ្នកប្រើប្រាស់')
            : 'អ្នកប្រើប្រាស់';

        // ✅ ទាញ FCM Token របស់អ្នកទទួល
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(receiverId)
            .get();

        if (!userDoc.exists) return null;


        const token = userDoc.data().fcmToken;


        if (token) {
            // ✅ ប្រើឈ្មោះអ្នកផ្ញើជាចំណងជើង
            const messageBody = data.message || "បានផ្ញើសារថ្មី...";

            const message = {
                token: token,
                notification: {
                    title: senderName, // ✅ ឈ្មោះអ្នកផ្ញើ
                    body: messageBody,
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "order_channel",
                        icon: 'ic_stat_sesan',
                        color: '#FF4500',
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    }
                },
                data: {
                    chatId: event.params.chatDocId,
                    senderId: senderId,
                    senderName: senderName,
                }
            };


            await admin.messaging().send(message);
            console.log('✅ Chat notification sent to:', receiverId);
        }
    } catch (error) {
        console.error("Error sending chat notification:", error);
    }
    return null;
});


exports.notifyAdminOnNewOrder = onDocumentCreated({
    document: "orders/{orderId}",
    region: "asia-southeast1"
}, async (event) => {
    const orderData = event.data.data();


    if (orderData.status === "pending") {
        try {
            // ✅ ដាក់ UID របស់ Admin នៅទីនេះ
            const adminUID = "WBdQVvrgEIPBTcgIlumu6bAZGUl2"; // ជំនួសដោយ UID ពិតរបស់ Admin

            // ទាញយក FCM Token របស់ Admin
            const adminDoc = await admin.firestore()
                .collection("users")
                .doc(adminUID)
                .get();

            if (adminDoc.exists) {
                const token = adminDoc.data().fcmToken;

                if (token) {
                    const message = {
                        token: token,
                        notification: {
                            title: "📦 Admin មានការកុម្ម៉ង់ថ្មី!",
                            body: "តម្លៃសរុប៖ " + (orderData.total_amount || 0) + "៛",
                        },
                        android: {
                            priority: "high",
                            notification: {
                                channelId: "order_channel",
                                priority: "high",
                                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                            }
                        }
                    };

                    await admin.messaging().send(message);
                    console.log("Notification sent to admin:", adminUID);
                }
            }
        } catch (error) {
            console.error("Error sending admin notification:", error);
        }
    }
    return null;
});


// 💰 គណនេយ្យករអូតូ (រុញលុយឱ្យអ្នកលក់ក្រោយ ៥ ថ្ងៃ)
exports.scheduledWalletSettlement = onSchedule({
    schedule: "0 0 * * *",
    timeZone: "Asia/Phnom_Penh",
    region: "asia-southeast1"
}, async (event) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // កាលបរិច្ឆេទ ៥ ថ្ងៃមុន
    const fiveDaysAgo = new Date(now.toDate().getTime() - 5 * 24 * 60 * 60 * 1000);
    const fiveDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(fiveDaysAgo);


    const ordersSnapshot = await db.collection("orders")
        .where("is_settled", "==", false) // រកបុងដែលមិនទាន់ទូទាត់
        .where("packing_date", "<=", fiveDaysAgoTimestamp)
        .get();


    if (ordersSnapshot.empty) return null;


    const batch = db.batch();


    ordersSnapshot.forEach((doc) => {
        const orderData = doc.data();
        const sellerId = orderData.seller_id;
        const earnings = parseFloat(orderData.seller_earnings || 0);


        if (sellerId && earnings > 0) {
            const userRef = db.collection("users").doc(sellerId);
            const orderRef = db.collection("orders").doc(doc.id);


            // ១. ប្ដូរលុយក្នុងកាបូបអ្នកលក់
            batch.set(userRef, {
                "wallet_balance": admin.firestore.FieldValue.increment(-earnings), // ដកពី Pending
                "available_balance": admin.firestore.FieldValue.increment(earnings), // បូកចូល Available
            }, { merge: true });


            // ២. 🎯 សំខាន់បំផុត៖ Update បុងនេះថាបានទូទាត់រួចហើយ (Clear បុង)
            batch.update(orderRef, {
                "is_settled": true,
                "settled_at": now // ដាក់ថ្ងៃដែលទូទាត់ទុកមើល
            });
        }
    });


    return batch.commit();
});


// ⚡ អាដិតលុយភ្លាមៗ (Real-time Today Income)
exports.onOrderPackingUpdate = onDocumentUpdated({
    document: "orders/{orderId}", // 🎯 ត្រូវតែមានជួរនេះ
    region: "asia-southeast1"
}, async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();


    // បើ Status ទើបតែដូរពីអីផ្សេង មកជា 'packing'
    if (newData.status === 'packing' && oldData.status !== 'packing') {
        const sellerId = newData.seller_id;
        const earnings = parseFloat(newData.seller_earnings || 0);


        if (sellerId && earnings > 0) {
            const userRef = admin.firestore().collection("users").doc(sellerId);

            // បូកចូល today_income ភ្លាមៗ (វានឹងបង្កើត Key អូតូបើមិនទាន់មាន)
            await userRef.set({
                "today_income": admin.firestore.FieldValue.increment(earnings)
            }, { merge: true });
        }
    }
});


// 🎯 ប្រើ onDocumentUpdated របស់ v2 វិញដើម្បីកុំឱ្យវា Error
exports.approveSale = onDocumentUpdated({
    document: 'sales/{saleId}',
    region: 'asia-southeast1' // ដាក់ឱ្យត្រូវជាមួយ Region របស់មេ
}, async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();


    if (newData.status === 'completed' && oldData.status !== 'completed') {
        const sellerId = newData.sellerId;
        const amount = newData.amount;


        if (!sellerId || !amount) return null;


        const userRef = admin.firestore().collection('users').doc(sellerId);


        try {
            return await admin.firestore().runTransaction(async (transaction) => {
                const userDoc = await transaction.get(userRef);
                if (!userDoc.exists) return;


                transaction.update(userRef, {
                    // ១. ដកចេញពីលុយរងចាំ
                    wallet_balance: admin.firestore.FieldValue.increment(-amount),
                    // ២. បញ្ចូលទៅក្នុងលុយអាចដកបាន
                    available_balance: admin.firestore.FieldValue.increment(amount)
                });
            });
        } catch (error) {
            console.error("Transaction failed: ", error);
        }
    }
    return null;
});
// 💰 មុខងារដកប្រាក់ចំណូល និងជូនដំណឹងទៅ Admin ភ្លាមៗ (Secure Withdraw)
exports.secureWithdraw = onCall({
    region: "asia-southeast1"
}, async (request) => {
    // ១. ទាញទិន្នន័យពី App
    const amount = request.data.amount;
    const inputPin = request.data.pin;
    const uid = request.data.uid;


    // ២. ឆែកសុពលភាពទិន្នន័យ
    if (!uid) {
        throw new HttpsError('unauthenticated', 'រកមិនឃើញអត្តសញ្ញាណអ្នកប្រើប្រាស់! សូមសាកល្បង Login ម្ដងទៀត។');
    }


    if (amount <= 0) {
        throw new HttpsError('invalid-argument', 'ចំនួនទឹកប្រាក់ត្រូវតែធំជាង ០៛');
    }


    try {
        const db = admin.firestore();
        const userRef = db.collection("users").doc(uid);
        const userDoc = await userRef.get();


        if (!userDoc.exists) {
            throw new HttpsError('not-found', 'រកមិនឃើញគណនីអ្នកប្រើប្រាស់ឡើយ');
        }


        const userData = userDoc.data();


        // ៣. ផ្ទៀងផ្ទាត់ PIN
        if (userData.pin !== inputPin) {
            throw new HttpsError('permission-denied', 'លេខសម្ងាត់ភីន (PIN) មិនត្រឹមត្រូវទេ!');
        }


        // ៤. ឆែកសមតុល្យលុយ
        const currentBalance = userData.available_balance || 0;
        if (currentBalance < amount) {
            throw new HttpsError('resource-exhausted', 'សមតុល្យលុយរបស់មេមិនគ្រប់គ្រាន់សម្រាប់ដកចំនួននេះទេ');
        }


        // 🔢 Format លុយឱ្យមានក្បៀស (ឧទាហរណ៍៖ 150,000) សម្រាប់ផ្ញើសារទៅ Admin
        const formattedAmount = Number(amount).toLocaleString("en-US");
        const sellerName = userData.full_name_kh || userData.full_name || "មិនស្គាល់ឈ្មោះ";


        // ៥. ចាប់ផ្ដើមដកលុយ (Transaction)
        const withdrawRequestId = await db.runTransaction(async (t) => {
            // ក. ដកលុយពី available_balance
            t.update(userRef, {
                available_balance: admin.firestore.FieldValue.increment(-amount)
            });


            // ខ. បង្កើតបុងដកលុយ (Withdraw Request)
            const withdrawRef = db.collection("withdraw_requests").doc();
            t.set(withdrawRef, {
                uid: uid,
                seller_id: uid, // ដាក់សមកាលកម្មដើម្បីកុំឱ្យខុសលក្ខខណ្ឌចាស់
                seller_name: sellerName,
                bank_name: userData.bank_name || "ABA",
                account_name: sellerName,
                account_number: userData.bank_account_number || "",
                amount: amount,
                khqr_url: userData.bank_qr_url || "",
                status: "pending",
                created_at: admin.firestore.FieldValue.serverTimestamp(),
                method: "ABA/Other"
            });


            return withdrawRef.id;
        });


        // ─── 🔔 ផ្នែកបន្ថែមថ្មី៖ ផ្ញើសារជូនដំណឹងទៅកាន់ Admin ភ្លាមៗ ───
        try {
            const adminUID = "WBdQVvrgEIPBTcgIlumu6bAZGUl2"; // Admin ID របស់មេ
            const adminDoc = await db.collection("users").doc(adminUID).get();


            const notificationTitle = "💰 មានសំណើដកប្រាក់ថ្មី!";
            const notificationBody = `អ្នកលក់៖ ${sellerName} បានស្នើដកប្រាក់ចំនួន ${formattedAmount} ៛`;


            // ក. រក្សាទុកក្នុង In-App Notification របស់ Admin សម្រាប់បង្ហាញក្នុង App
            await db.collection("users")
                .doc(adminUID)
                .collection("notifications")
                .add({
                    title: notificationTitle,
                    body: notificationBody,
                    type: "withdraw_request",
                    requestId: withdrawRequestId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });


            // ខ. បាញ់ Push Notification ទៅលើអេក្រង់ទូរស័ព្ទ Admin (FCM)
            if (adminDoc.exists) {
                const adminToken = adminDoc.data().fcmToken; // ទាញ Token របស់ Admin


                if (adminToken) {const message = {
                        token: adminToken,
                        notification: {
                            title: notificationTitle,
                            body: notificationBody,
                        },
                        android: {
                            priority: "high",
                            notification: {
                                channelId: "order_channel", // ប្រើ Channel ដូចកូដចាស់មេ
                                icon: 'ic_stat_sesan',
                                color: '#FF4500',
                                sound: "default",
                                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                            }
                        },
                        data: {
                            requestId: withdrawRequestId,
                            type: 'withdraw_request',
                        }
                    };


                    await admin.messaging().send(message);
                    console.log("✅ Sent withdraw notification to admin successfully!");
                }
            }
        } catch (notiError) {
            console.error("⚠️ Error sending withdraw notification to admin:", notiError);
            // មិន return error ទេដើម្បីកុំឱ្យគាំងការដកលុយរបស់ User
        }


        return {
            success: true,
            message: "សំណើដកប្រាក់ចំនួន " + formattedAmount + "៛ របស់មេត្រូវបានបញ្ជូនទៅកាន់ Admin រួចរាល់!"
        };


    } catch (error) {
        console.error("Withdraw Error:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError('internal', 'មានបញ្ហាបច្ចេកទេស៖ ' + error.message);
    }
});


// 🔔 ជូនដំណឹងទៅម្ចាស់ទំនិញ ពេល Admin អនុម័តការដេញថ្លៃ
exports.notifyOwnerOnAuctionApproved = onDocumentCreated({
    document: "products/{productId}",
    region: "asia-southeast1"
}, async (event) => {
    const productData = event.data.data();


    // ពិនិត្យថាជា Auction ដែលទើបនឹង Approve
    // (_approveAuction បង្កើត Document ថ្មីដែលមាន status: 'auction')
    if (productData.status !== 'auction') {
        return null;
    }


    const ownerId = productData.owner_id;
    const productName = productData.product_name || 'ទំនិញ';
    const productId = event.params.productId;
    const startPrice = productData.start_price || 0;
    const endTime = productData.end_time;


    if (!ownerId) {
        console.log('No owner_id found for product:', productId);
        return null;
    }


    try {
        // ១. ទាញយក FCM Token របស់ម្ចាស់ទំនិញ
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(ownerId)
            .get();


        if (!userDoc.exists) {
            console.log('User not found:', ownerId);
            return null;
        }


        const userData = userDoc.data();
        const token = userData.fcmToken;


        if (!token) {
            console.log('No FCM token for user:', ownerId);
            return null;
        }


        // ២. បង្កើតសារជូនដំណឹង
        let endTimeStr = '';
        if (endTime) {
            const endDate = endTime.toDate();
            endTimeStr = `\nបញ្ចប់នៅ៖ ${endDate.getDate()}/${endDate.getMonth() + 1}/${endDate.getFullYear()} ${endDate.getHours()}:${String(endDate.getMinutes()).padStart(2, '0')}`;
        }


        const message = {
            token: token,
            notification: {
                title: "🎉 ការដេញថ្លៃត្រូវបានអនុម័ត!",
body: `ទំនិញ "${productName}" របស់អ្នកត្រូវបានអនុម័តដោយ Admin។ តម្លៃចាប់ផ្តើម៖ ${startPrice} ៛${endTimeStr}`,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    icon: 'ic_stat_sesan',
                    color: '#FF4500',
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                }
            },
            data: {
                productId: productId,
                type: 'auction_approved',
            }
        };


        // ៣. ផ្ញើ Notification
        const response = await admin.messaging().send(message);
        console.log('Auction approval notification sent:', response);


        // ៤. រក្សាទុក Notification ក្នុង Firestore
        await admin.firestore()
            .collection("users")
            .doc(ownerId)
            .collection("notifications")
            .add({
                title: "ការដេញថ្លៃត្រូវបានអនុម័ត!",
                body: `ទំនិញ "${productName}" ត្រូវបានអនុម័ត`,
                productId: productId,
                type: 'auction_approved',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });


        return null;
    } catch (error) {
        console.error("Error sending auction approval notification:", error);
        return null;
    }
});


exports.notifyOwnerOnNewBid = onDocumentCreated({
    document: "auction_products/{productId}/bids/{bidId}",
    region: "asia-southeast1"
}, async (event) => {
    console.log('🔥 New bid received!');
    console.log('Product ID:', event.params.productId);
    console.log('Bid ID:', event.params.bidId);

    const bidData = event.data.data();
    console.log('Bid data:', JSON.stringify(bidData));

    const productId = event.params.productId;


    try {
        const productDoc = await admin.firestore()
            .collection("auction_products")
            .doc(productId)
            .get();


        if (!productDoc.exists) {
            console.log('❌ Product not found:', productId);
            return null;
        }


        const productData = productDoc.data();
        console.log('Product data:', JSON.stringify(productData));

        const ownerId = productData.owner_id;
        console.log('Owner ID:', ownerId);


        if (!ownerId) {
            console.log('❌ No owner_id');
            return null;
        }

        if (bidData.bidder_id === ownerId) {
            console.log('❌ Bidder is owner, skipping');
            return null;
        }


        const userDoc = await admin.firestore()
            .collection("users")
            .doc(ownerId)
            .get();


        if (!userDoc.exists) {
            console.log('❌ Owner user doc not found');
            return null;
        }


        const userData = userDoc.data();
        console.log('Owner data keys:', Object.keys(userData));

        const token = userData.fcmToken;
        console.log('FCM Token exists:', !!token);


        if (!token) {
            console.log('❌ No FCM token for owner');
            return null;
        }


        const productName = productData.product_name || 'ទំនិញ';
        const bidAmount = bidData.bid_amount || 0;
        const bidderName = bidData.bidder_name || 'អ្នកដេញថ្លៃ';


        console.log('📤 Sending notification to owner...');

        const message = {
            token: token,
            notification: {
                title: "💰 មានអ្នកដេញថ្លៃថ្មី!",
                body: bidderName + ' បានដេញថ្លៃ ' + bidAmount + ' ៛ លើ "' + productName + '"',
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    icon: 'ic_stat_sesan',
                    color: '#FF4500',
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                }
            },
            data: {
                productId: productId,
                type: 'new_bid',
            }
        };


        const response = await admin.messaging().send(message);
        console.log('✅ Notification sent successfully:', response);


        return null;
    } catch (error) {
        console.error('❌ Error:', error);
        console.error('Error message:', error.message);
        return null;
    }
});
// 🔔 ជូនដំណឹងទៅម្ចាស់ទំនិញ ពេល Admin អនុម័ត
exports.notifyOwnerOnAuctionApproved = onDocumentUpdated({
    document: "auction_products/{productId}",
    region: "asia-southeast1"
}, async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const productId = event.params.productId;


    // ✅ ពិនិត្យថា Status ទើបតែប្តូរពី pending → auction
    if (beforeData.status !== 'auction' && afterData.status === 'auction') {
        const productName = afterData.product_name || 'ទំនិញ';
        const startPrice = afterData.start_price || 0;
        const ownerId = afterData.owner_id;
        const endTime = afterData.end_time;


        if (!ownerId) return null;


        try {
            // 1. ជូនដំណឹងទៅម្ចាស់ទំនិញ
            const userDoc = await admin.firestore()
                .collection("users")
                .doc(ownerId)
                .get();


            if (userDoc.exists) {
                const token = userDoc.data().fcmToken;


                if (token) {
                    let endTimeStr = '';
                    if (endTime) {
                        const endDate = endTime.toDate();
                        endTimeStr = ' បញ្ចប់នៅ: ' + endDate.getDate() + '/' + (endDate.getMonth() + 1) + '/' + endDate.getFullYear();
                    }


                    const ownerMessage = {
                        token: token,
                        notification: {
                            title: "🎉 ការដេញថ្លៃត្រូវបានអនុម័ត!",
                            body: 'ទំនិញ "' + productName + '" របស់អ្នកត្រូវបានអនុម័ត។ តម្លៃចាប់ផ្តើម: ' + startPrice + ' ៛' + endTimeStr,
                        },
                        android: {
                            priority: "high",
                            notification: {
                                channelId: "high_importance_channel",
                                icon: 'ic_stat_sesan',
                                color: '#FF4500',
                                sound: "default",
                                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                            }
                        },
                        data: {
                            productId: productId,
                            type: 'auction_approved',
                        }
                    };


                    await admin.messaging().send(ownerMessage);
                }


                // រក្សាទុក Notification ក្នុង Firestore
                await admin.firestore()
                    .collection("users")
                    .doc(ownerId)
                    .collection("notifications")
                    .add({
                        title: "ការដេញថ្លៃត្រូវបានអនុម័ត!",
                        body: 'ទំនិញ "' + productName + '" ត្រូវបានអនុម័ត',
                        productId: productId,
                        type: 'auction_approved',
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
            }


            // 2. ជូនដំណឹងទៅកាន់អ្នកប្រើប្រាស់ទាំងអស់
            let allUsersEndTimeStr = '';
            if (endTime) {
                const endDate = endTime.toDate();
                allUsersEndTimeStr = ' បញ្ចប់នៅ: ' + endDate.getDate() + '/' + (endDate.getMonth() + 1) + '/' + endDate.getFullYear();
            }


            const allUsersMessage = {
                topic: 'all_users',
                notification: {
                    title: "🎉 មានការដេញថ្លៃថ្មី!",
                    body: 'ទំនិញ "' + productName + '" តម្លៃចាប់ផ្តើម ' + startPrice + ' ៛' + allUsersEndTimeStr + ' ចូលដេញថ្លៃឥឡូវនេះ!',
                },
                android: {
                    priority: "high",
                    notification: {channelId: "high_importance_channel",
                        icon: 'ic_stat_sesan',
                        color: '#FF4500',
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    }
                },
                data: {
                    productId: productId,
                    type: 'auction_approved_all',
                }
            };


            await admin.messaging().send(allUsersMessage);
            console.log('✅ Auction approved notifications sent:', productId);


            return null;
        } catch (error) {
            console.error('❌ Error:', error);
            return null;
        }
    }
    return null;
});
exports.productPreview = functions.https.onRequest(async (req, res) => {
    try {
        const parts = req.path.split('/').filter(Boolean);
        const productId = parts.pop();


        if (!productId) {
            return res.status(400).send('Missing product ID');
        }


        const doc = await admin.firestore().collection('products').doc(productId).get();


        if (!doc.exists) return res.status(404).send('Not found');


        const data = doc.data();


        const escapeHtml = (str) => String(str ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');


        const rawImageUrl = (data.image_urls && data.image_urls.length > 0)
            ? data.image_urls[0]
            : (data.image_url || '');


        const rawPrice = data.price || 0;
        const cleanPrice = typeof rawPrice === 'string' ? rawPrice.replace(/,/g, '') : rawPrice;
        const numPrice = Number(cleanPrice);
        const formattedPrice = isNaN(numPrice) ? '0' : numPrice.toLocaleString('en-US');


        const productName = escapeHtml(data.product_name || 'ទំនិញ');
        const location = escapeHtml(data.location || '');
        const sellerName = escapeHtml(data.seller_name || data.owner_name || 'មិនស្គាល់');
        const sellerPhone = escapeHtml(data.phone1 || data.seller_phone || '');
        const imageUrl = escapeHtml(rawImageUrl);
        const safeProductId = escapeHtml(productId);


        const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta property="og:title" content="${productName}">
    <meta property="og:description" content="តម្លៃ៖ ${formattedPrice} ៛">
    <meta property="og:image" content="${imageUrl}">
    <meta property="og:url" content="https://sesanshop.com/product/${safeProductId}">
    <meta property="og:type" content="website">
    <title>${productName} - Sesan Marketplace</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; padding: 20px; }
        .card { max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .card img { width: 100%; height: 300px; object-fit: cover; }
        .card-body { padding: 20px; }
        .card-body h1 { font-size: 20px; margin-bottom: 8px; color: #333; }
        .price { font-size: 28px; font-weight: bold; color: #e53935; margin-bottom: 8px; }
        .location { color: #666; font-size: 14px; margin-bottom: 8px; }
        .seller { color: #666; font-size: 14px; margin-bottom: 15px; }
        .btn { display: block; text-align: center; background: #1B5E20; color: white; padding: 14px; border-radius: 25px; text-decoration: none; font-weight: bold; font-size: 16px; margin-bottom: 10px; }
        .btn-outline { display: block; text-align: center; border: 2px solid #1B5E20; color: #1B5E20; padding: 12px; border-radius: 25px; text-decoration: none; font-weight: bold; font-size: 14px; margin-bottom: 10px; }
        .app-badge { text-align: center; margin-top: 15px; color: #999; font-size: 12px; }
        .status { text-align: center; margin-top: 10px; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <div class="card">
        ${imageUrl ? `<img src="${imageUrl}" alt="${productName}">` : ''}
        <div class="card-body">
            <h1>${productName}</h1>
            <div class="price">${formattedPrice} ៛</div>
            ${location ? `<div class="location">📍 ${location}</div>` : ''}
            ${sellerName ? `<div class="seller">👤 ${sellerName} ${sellerPhone ? '| 📞 ' + sellerPhone : ''}</div>` : ''}</div>
    </div>
    <div style="text-align: center; margin-top: 20px;">
        <a href="javascript:void(0)" onclick="openApp()" class="btn">🔗 មើលទំនិញក្នុង Sesan App</a>
        <a href="https://play.google.com/store/apps/details?id=com.sesan.app" class="btn-outline">📲 ទាញយក App Android</a>
        <a href="https://apps.apple.com/app/sesan-app/idXXXXXXXXXX" class="btn-outline">📱 ទាញយក App iOS</a>
    </div>
    <div id="status" class="status"></div>


   <script>
function openApp() {
    const productId = "${safeProductId}";
    const fallbackUrl = "https://sesanshop.com/product/" + productId;
    const ua = navigator.userAgent;


    if (/android/i.test(ua)) {
        // Android Intent URL: opens app if installed, falls back to browser URL if not
        const intentUrl = "intent://product/" + productId +
            "#Intent;scheme=sesanapp;package=com.sesan.app;S.browser_fallback_url=" +
            encodeURIComponent(fallbackUrl) + ";end";
        window.location.href = intentUrl;
    } else if (/iphone|ipad|ipod/i.test(ua)) {
        // iOS: try custom scheme, fallback via timeout
        const appScheme = "sesanapp://product/" + productId;
        const start = Date.now();
        window.location.href = appScheme;
        setTimeout(function() {
            if (Date.now() - start < 2000) {
                window.location.href = fallbackUrl;
            }
        }, 1000);
    } else {
        // Desktop / unknown -> go straight to web
        window.location.href = fallbackUrl;
    }
}
</script>
</body>
</html>`;


        res.set('Cache-Control', 'public, max-age=3600');
        return res.status(200).send(html);
    } catch (e) {
        console.error('productPreview error:', e);
        return res.status(500).send('Error');
    }
});
// 🔔 ជូនដំណឹងទៅ Admin ពេលមានការដេញថ្លៃថ្មី (Pending)
exports.notifyAdminOnNewAuction = onDocumentCreated({
    document: "auction_products/{productId}",
    region: "asia-southeast1"
}, async (event) => {
    const productData = event.data.data();

    // ✅ ពិនិត្យតែ status: "pending"
    if (productData.status !== 'pending') {
        return null;
    }

    const productName = productData.product_name || 'ទំនិញថ្មី';
    const startPrice = productData.start_price || 0;
    const ownerName = productData.owner_name || 'មិនស្គាល់';
    const productId = event.params.productId;


    try {
        const adminUID = "WBdQVvrgEIPBTcgIlumu6bAZGUl2";

        const adminDoc = await admin.firestore()
            .collection('users')
            .doc(adminUID)
            .get();


        if (!adminDoc.exists) return null;


        const adminToken = adminDoc.data().fcmToken;


        if (!adminToken) return null;


        const message = {
            token: adminToken,
            notification: {
                title: "📢 មានការដេញថ្លៃថ្មីរង់ចាំអនុម័ត!",
                body: '"' + productName + '" ពី ' + ownerName + ' | តម្លៃ: ' + startPrice + ' ៛',
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "order_channel",
                    icon: 'ic_stat_sesan',
                    color: '#FF4500',
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                }
            },
            data: {
                productId: productId,
                type: 'new_auction_pending',
            }
        };


        await admin.messaging().send(message);
        console.log('✅ Admin notified about new auction:', productId);


        return null;
    } catch (error) {
        console.error('❌ Error:', error);
        return null;
    }
});
// 🔔 ជូនដំណឹងទៅ All Users ពេល Admin អនុម័តការដេញថ្លៃ
exports.notifyAllUsersOnAuctionApproved = onDocumentUpdated({
    document: "auction_products/{productId}",
    region: "asia-southeast1"
}, async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const productId = event.params.productId;


    // ✅ ពិនិត្យថា Status ទើបតែប្តូរពី pending → auction
    if (beforeData.status !== 'auction' && afterData.status === 'auction') {
        const productName = afterData.product_name || 'ទំនិញ';
        const startPrice = afterData.start_price || 0;
        const endTime = afterData.end_time;
        const ownerName = afterData.owner_name || 'មិនស្គាល់';


        try {
            let endTimeStr = '';
            if (endTime) {
                const endDate = endTime.toDate();
                endTimeStr = ' | បញ្ចប់: ' + endDate.getDate() + '/' + (endDate.getMonth() + 1) + '/' + endDate.getFullYear();
            }


            // ✅ បាញ់ទៅកាន់អ្នកប្រើប្រាស់ទាំងអស់
            const allUsersMessage = {
                topic: 'all_users',
                notification: {
                    title: "🎉 មានការដេញថ្លៃថ្មី!",
                    body: '"' + productName + '" ពី ' + ownerName + ' | តម្លៃចាប់ផ្តើម: ' + startPrice + ' ៛' + endTimeStr + ' | ចូលដេញថ្លៃឥឡូវនេះ!',
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "high_importance_channel",
                        icon: 'ic_stat_sesan',
                        color: '#FF4500',
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
                data: {
                    productId: productId,
                    type: 'auction_started',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                }
            };


            const response = await admin.messaging().send(allUsersMessage);
            console.log('✅ Sent to all users for auction:', productId, response);


            // រក្សាទុកក្នុង Collection announcements
            await admin.firestore()
                .collection("announcements")
                .add({
                    title: "ការដេញថ្លៃថ្មី!",
                    body: '"' + productName + '" តម្លៃចាប់ផ្តើម ' + startPrice + ' ៛',
                    productId: productId,
                    type: 'auction_started',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });


            return null;
        } catch (error) {
            console.error('❌ Error sending to all users:', error);
            return null;
        }
    }
    return null;
});


// 🔔 ជូនដំណឹងទៅម្ចាស់ទំនិញ ពេលមាន Comment ថ្មី
exports.notifyOwnerOnNewComment = onDocumentCreated({
    document: "products/{productId}/comments/{commentId}",
    region: "asia-southeast1"
}, async (event) => {
    const commentData = event.data.data();
    const productId = event.params.productId;

    console.log('🔥 New comment on product:', productId);

    try {
        // 1. ទាញព័ត៌មានទំនិញ
        const productDoc = await admin.firestore()
            .collection("products")
            .doc(productId)
            .get();


        if (!productDoc.exists) {
            console.log('❌ Product not found');
            return null;
        }


        const productData = productDoc.data();
        const ownerId = productData.seller_id || productData.owner_id;
        const productName = productData.product_name || 'ទំនិញ';
        const commenterName = commentData.userName || 'អ្នកប្រើប្រាស់';
        const commentText = commentData.content || '';


        if (!ownerId) {
            console.log('❌ No owner_id found');
            return null;
        }


        // 2. កុំផ្ញើ Noti បើម្ចាស់ទំនិញខមិនខ្លួនឯង
        if (commentData.userId === ownerId) {
            console.log('❌ Owner commented on own product, skipping');
            return null;
        }


        // 3. ទាញ FCM Token របស់ម្ចាស់ទំនិញ
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(ownerId)
            .get();


        if (!userDoc.exists) {
            console.log('❌ Owner user doc not found');
            return null;
        }


        const token = userDoc.data().fcmToken;


        if (!token) {
            console.log('❌ No FCM token for owner');
            return null;
        }


        // 4. បង្កើតសារជូនដំណឹង
        let bodyText = commenterName + ' បានបញ្ចេញមតិ';
        if (commentText) {
            bodyText += ': "' + (commentText.length > 50 ? commentText.substring(0, 50) + '...' : commentText) + '"';
        }
        bodyText += ' លើទំនិញ "' + productName + '"';


        const message = {
            token: token,
            notification: {
                title: "💬 មានមតិយោបល់ថ្មី!",
                body: bodyText,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "order_channel",
                    icon: 'ic_stat_sesan',
                    color: '#FF4500',
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                }
            },
            data: {
                productId: productId,
                commentId: event.params.commentId,
                type: 'new_comment',
            }
        };


        const response = await admin.messaging().send(message);
        console.log('✅ Comment notification sent to owner:', ownerId);


        // 5. រក្សាទុកក្នុង Firestore Notifications
        await admin.firestore()
            .collection("users")
            .doc(ownerId)
            .collection("notifications")
            .add({
                title: "មតិយោបល់ថ្មី",
                body: bodyText,
                productId: productId,
                commentId: event.params.commentId,
                type: 'new_comment',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });


        return null;
    } catch (error) {
        console.error('❌ Error:', error);
        return null;
    }
});


// 🔔 ជូនដំណឹងទៅម្ចាស់ Comment ពេលមាន Reply
exports.notifyOnCommentReply = onDocumentCreated({
    document: "products/{productId}/comments/{commentId}/replies/{replyId}",
    region: "asia-southeast1"
}, async (event) => {
    const replyData = event.data.data();
    const productId = event.params.productId;
    const commentId = event.params.commentId;

    console.log('🔥 New reply on comment:', commentId);

    try {
        // 1. ទាញព័ត៌មាន Comment ដើម
        const commentDoc = await admin.firestore()
            .collection("products")
            .doc(productId)
            .collection("comments")
            .doc(commentId)
            .get();


        if (!commentDoc.exists) {
            console.log('❌ Original comment not found');
            return null;
        }


        const commentData = commentDoc.data();
        const commentOwnerId = commentData.userId;
        const commentOwnerName = commentData.userName || 'អ្នកប្រើប្រាស់';
        const replierName = replyData.userName || 'អ្នកប្រើប្រាស់';
        const replyText = replyData.content || '';


        if (!commentOwnerId) {
            console.log('❌ No comment owner_id');
            return null;
        }


        // 2. កុំផ្ញើ Noti បើ Reply ខ្លួនឯង
        if (replyData.userId === commentOwnerId) {
            console.log('❌ Owner replied to own comment, skipping');
            return null;
        }


        // 3. ទាញ FCM Token របស់ម្ចាស់ Comment
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(commentOwnerId)
            .get();


        if (!userDoc.exists) {
            console.log('❌ Comment owner user doc not found');
            return null;
        }


        const token = userDoc.data().fcmToken;


        if (!token) {
            console.log('❌ No FCM token for comment owner');
            return null;
        }


        // 4. ទាញឈ្មោះទំនិញ
        const productDoc = await admin.firestore()
            .collection("products")
            .doc(productId)
            .get();
        const productName = productDoc.exists ? (productDoc.data().product_name || 'ទំនិញ') : 'ទំនិញ';


        // 5. បង្កើតសារជូនដំណឹង
        let bodyText = replierName + ' បានឆ្លើយតបមតិរបស់អ្នក';
        if (replyText) {
            bodyText += ': "' + (replyText.length > 50 ? replyText.substring(0, 50) + '...' : replyText) + '"';
        }
        bodyText += ' លើទំនិញ "' + productName + '"';


        const message = {
            token: token,
            notification: {
                title: "💬 មានការឆ្លើយតបមតិរបស់អ្នក!",
                body: bodyText,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "order_channel",
                    icon: 'ic_stat_sesan',
                    color: '#FF4500',
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                }
            },
            data: {
                productId: productId,
                commentId: commentId,
                replyId: event.params.replyId,
                type: 'comment_reply',
            }
        };


        const response = await admin.messaging().send(message);
        console.log('✅ Reply notification sent to comment owner:', commentOwnerId);


        // 6. រក្សាទុកក្នុង Firestore Notifications
        await admin.firestore()
            .collection("users")
            .doc(commentOwnerId)
            .collection("notifications")
            .add({
                title: "ការឆ្លើយតបមតិ",
                body: bodyText,
                productId: productId,
                commentId: commentId,
                replyId: event.params.replyId,
                type: 'comment_reply',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });


        return null;
    } catch (error) {
        console.error('❌ Error:', error);
        return null;
    }
});

