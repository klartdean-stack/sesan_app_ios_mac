const {onDocumentUpdated, onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");


if (admin.apps.length === 0) {
    admin.initializeApp();
}


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
    const senderId = data.sender; // 👈 ទាញ ID អ្នកផ្ញើចេញពី Database
  if (!receiverId || senderId === receiverId) {
        console.log("អ្នកផ្ញើ និងអ្នកទទួលជាមនុស្សតែម្នាក់។ មិនផ្ញើ Noti ឡើយ។");
        return null;
  }
    try {
        const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
        if (!userDoc.exists) return null;


        const token = userDoc.data()?.fcmToken;


        if (token) {
            const message = {
                token: token,
                notification: {
                    title: "Sesan App: សារថ្មី 📩",
                    body: data.message || "បានផ្ញើសារថ្មី..."
                },
                // រកមើល exports.notifyOnNewChatMessage ហើយកែដូចគ្នា
android: {
    priority: "high",
    notification: {
        channelId: "order_channel", // 🎯 ប្ដូរឱ្យដូចគ្នាទាំងអស់
        icon: 'ic_stat_sesan',
        color: '#FF4500',
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
    }
},
                data: {
                    chatId: event.params.chatDocId
                }
            };


            await admin.messaging().send(message);
        }
    } catch (error) {
        console.error("Error sending message:", error);
    }
    return null;
});
exports.notifyAdminOnNewOrder = onDocumentCreated({
    document: "orders/{orderId}",
    region: "asia-southeast1"
}, async (event) => {
    const orderData = event.data.data();


    if (orderData.status === "pending") {
        const message = {
            topic: "admin_orders",
            notification: {
                title: "📦 Amin មានការកុម្ម៉ង់ថ្មី!",
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
        return admin.messaging().send(message);
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
// 💰 មុខងារដកប្រាក់ចំណូល (Secure Withdraw)
// កូដនេះនឹងទទួល uid ផ្ទាល់ពី App (SharedPreferences)
exports.secureWithdraw = onCall({
    region: "asia-southeast1"
}, async (request) => {
    // ១. ទាញទិន្នន័យពី App
    const amount = request.data.amount;
    const inputPin = request.data.pin;
    const uid = request.data.uid; // 🎯 ទទួល UID ដែលផ្ញើពី SharedPrefs


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


        // ៣. ផ្ទៀងផ្ទាត់ PIN (មេត្រូវមាន field 'pin' ក្នុង Collection users)
        if (userData.pin !== inputPin) {
            throw new HttpsError('permission-denied', 'លេខសម្ងាត់ភីន (PIN) មិនត្រឹមត្រូវទេ!');
        }


        // ៤. ឆែកសមតុល្យលុយ
        const currentBalance = userData.available_balance || 0;
        if (currentBalance < amount) {
            throw new HttpsError('resource-exhausted', 'សមតុល្យលុយរបស់មេមិនគ្រប់គ្រាន់សម្រាប់ដកចំនួននេះទេ');
        }


        // ៥. ចាប់ផ្ដើមដកលុយ (Transaction)
        await db.runTransaction(async (t) => {
            // ក. ដកលុយពី available_balance
            t.update(userRef, {
                available_balance: admin.firestore.FieldValue.increment(-amount)
            });


            // ខ. បង្កើតបុងដកលុយ (Withdraw Request)
            const withdrawRef = db.collection("withdraw_requests").doc();
            t.set(withdrawRef, {
                uid: uid,
                seller_name: userData.full_name || "Unknown",
                amount: amount,
                status: "pending",
                created_at: admin.firestore.FieldValue.serverTimestamp(),
                method: "ABA/Other" // មេអាចថែមព័ត៌មានធនាគារត្រង់នេះ
            });
        });


        return {
            success: true,
            message: "សំណើដកប្រាក់ចំនួន " + amount + "៛ របស់មេត្រូវបានបញ្ជូនទៅកាន់ Admin រួចរាល់!"
        };


    } catch (error) {
        console.error("Withdraw Error:", error);
        // បើវាជា HttpsError រួចហើយ ឱ្យវាបាញ់ទៅ App វិញតែម្ដង
        if (error instanceof HttpsError) throw error;
        throw new HttpsError('internal', 'មានបញ្ហាបច្ចេកទេស៖ ' + error.message);
    }
});

