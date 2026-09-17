/**
 * ==============================================================================
 * 🤖 TELEGRAM BOT CONTROLLER FOR SAIFEDDINE BOUMAZA TRADES
 * Bot Username: @HNTSB15_trades_bot
 * ==============================================================================
 */

const https = require('https');

const BOT_TOKEN = '8685200299:AAG2nR9wmeskmHH3ZHS7NWSTYANZcRUskQo';
const SUPABASE_URL = 'https://kbioxkoifvyivhkzbxke.supabase.co';
const SUPABASE_KEY = 'sb_publishable_TXezItY2oN4gFgCxDLqZPw_B_ormkoG';

// In-memory conversation state tracking per user
const userStates = {};

// Helper: Rock-solid Telegram API caller using https with IPv4 (family: 4)
function tg(method, body = {}) {
  return new Promise((resolve) => {
    const data = JSON.stringify(body);
    const req = https.request({
      hostname: 'api.telegram.org',
      path: `/bot${BOT_TOKEN}/${method}`,
      method: 'POST',
      family: 4,
      timeout: 15000,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => {
      let raw = '';
      res.on('data', chunk => raw += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(raw));
        } catch {
          resolve({ ok: false });
        }
      });
    });

    req.on('error', (err) => {
      console.error(`TG API error [${method}]:`, err.message);
      resolve({ ok: false });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ ok: false });
    });

    req.write(data);
    req.end();
  });
}

// Helper: Upload a photo/video buffer to permanent Catbox CDN
async function uploadToCatbox(fileBuffer, fileName = 'media.jpg') {
  try {
    const form = new FormData();
    form.append('reqtype', 'fileupload');
    const blob = new Blob([fileBuffer]);
    form.append('fileToUpload', blob, fileName);

    const res = await fetch('https://catbox.moe/user/api.php', {
      method: 'POST',
      body: form
    });
    const url = (await res.text()).trim();
    if (url.startsWith('https://')) return url;
    throw new Error('Upload failed: ' + url);
  } catch (err) {
    console.error('Catbox upload error:', err.message);
    return null;
  }
}

// Helper: Download a file from Telegram by file_id and re-upload to CDN
async function processTelegramFile(fileId) {
  try {
    const fileInfo = await tg('getFile', { file_id: fileId });
    if (!fileInfo.ok || !fileInfo.result.file_path) return null;

    const filePath = fileInfo.result.file_path;
    const downloadUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${filePath}`;

    const res = await fetch(downloadUrl);
    const buffer = Buffer.from(await res.arrayBuffer());

    const ext = filePath.split('.').pop() || 'jpg';
    const cdnUrl = await uploadToCatbox(buffer, `trade_${Date.now()}.${ext}`);
    return cdnUrl || downloadUrl;
  } catch (err) {
    console.error('Process Telegram file error:', err.message);
    return null;
  }
}

// Helper: Fetch all live trades from Supabase
async function getSupabaseTrades() {
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/managed_trades?select=*&order=created_at.desc`, {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': 'Bearer ' + SUPABASE_KEY
      }
    });
    return await res.json();
  } catch (err) {
    console.error('Fetch trades error:', err.message);
    return [];
  }
}

// Helper: Insert trade into Supabase
async function insertSupabaseTrade(trade) {
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/managed_trades`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': 'Bearer ' + SUPABASE_KEY,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify(trade)
    });
    return res.ok;
  } catch (err) {
    console.error('Insert trade error:', err.message);
    return false;
  }
}

// Helper: Delete trade from Supabase by ID
async function deleteSupabaseTrade(id) {
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/managed_trades?id=eq.${id}`, {
      method: 'DELETE',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': 'Bearer ' + SUPABASE_KEY
      }
    });
    return res.ok;
  } catch (err) {
    console.error('Delete trade error:', err.message);
    return false;
  }
}

// Main Menu Keyboard
function getMainMenuKeyboard() {
  return {
    keyboard: [
      [{ text: '➕ نشر صفقة جديدة 🚀' }],
      [{ text: '🗑️ حذف وإدارة الصفقات' }, { text: '🌐 معاينة الموقع' }]
    ],
    resize_keyboard: true
  };
}

// Reset user state
function resetState(chatId) {
  userStates[chatId] = {
    step: 'IDLE',
    trade: {
      images: [],
      deposit: '',
      profit: '',
      badge: 'RECORD PROFIT ⚡',
      badge_type: 'neon',
      desc: '',
      tweet_url: 'https://x.com/seifeddin06',
      split: 'Profit Split: 50/50'
    }
  };
}

// Handle Incoming Text & Commands
async function handleMessage(msg) {
  const chatId = msg.chat.id;
  const text = (msg.text || '').trim();

  if (!userStates[chatId]) resetState(chatId);
  const state = userStates[chatId];

  // Global cancel / restart / start
  if (text === '/start' || text === '/menu' || text === 'إلغاء ❌') {
    resetState(chatId);
    return tg('sendMessage', {
      chat_id: chatId,
      text: `👋 **أهلاً بك يا سيف الدين في بوت إدارة صفقات الموقع!** 💼\n\nمن هنا يمكنك نشر الصفقات الجديدة مباشرة على موقعك، أو حذف أي منشور بضغطة زر واحدة ومن هاتفك.\n\nاختر من الأزرار أدناه:`,
      parse_mode: 'Markdown',
      reply_markup: getMainMenuKeyboard()
    });
  }

  if (text === '🌐 معاينة الموقع') {
    return tg('sendMessage', {
      chat_id: chatId,
      text: `🌐 **رابط موقعك المباشر مع قسم الصفقات:**\nhttps://hntsb15.github.io/seifeddine-boumaza/#results`,
      parse_mode: 'Markdown',
      reply_markup: getMainMenuKeyboard()
    });
  }

  // 1. Delete / Manage Flow
  if (text === '🗑️ حذف وإدارة الصفقات' || text === '/list') {
    resetState(chatId);
    await tg('sendMessage', { chat_id: chatId, text: '⏳ جاري جلب الصفقات الحالية من موقعك...' });
    const trades = await getSupabaseTrades();
    if (!Array.isArray(trades) || !trades.length) {
      return tg('sendMessage', {
        chat_id: chatId,
        text: '⚠️ لا توجد صفقات حالياً في قاعدة البيانات.',
        reply_markup: getMainMenuKeyboard()
      });
    }

    await tg('sendMessage', {
      chat_id: chatId,
      text: `📋 **المنشورات الحالية على موقعك (${trades.length} منشور):**\nاضغط على زر [حذف 🗑️] أسفل أي منشور ترغب في إزالته:`,
      parse_mode: 'Markdown'
    });

    for (let i = 0; i < trades.length; i++) {
      const t = trades[i];
      const descSnippet = (t.description || '').substring(0, 60);
      const msgText = `📌 **منشور #${i + 1}**\n💰 الإيداع: \`${t.deposit_amount || 'N/A'}\`\n🚀 الربح: \`${t.profit_amount || 'N/A'}\`\n🏷️ الشارة: ${t.badge_text || ''}\n📅 التاريخ: ${t.published_date || ''}\n📝 ${descSnippet}...`;

      await tg('sendMessage', {
        chat_id: chatId,
        text: msgText,
        parse_mode: 'Markdown',
        reply_markup: {
          inline_keyboard: [
            [{ text: '🗑️ حذف هذا المنشور من الموقع', callback_data: `del_${t.id}` }]
          ]
        }
      });
    }
    return;
  }

  // 2. Start New Trade Wizard
  if (text === '➕ نشر صفقة جديدة 🚀' || text === '/new') {
    resetState(chatId);
    state.step = 'WAITING_MEDIA';
    return tg('sendMessage', {
      chat_id: chatId,
      text: `📸 **الخطوة 1 من 5: أرسل صور أو فيديو الصفقة**\n\nأرسل الآن صورة أو حتى 4 صور للصفقة (أو فيديو MP4).\n\nعندما تنتهي من إرسال الصور، اضغط زر **[ تم إرسال الصور ✅ ]** أدناه:`,
      parse_mode: 'Markdown',
      reply_markup: {
        keyboard: [
          [{ text: 'تم إرسال الصور ✅' }],
          [{ text: 'إلغاء ❌' }]
        ],
        resize_keyboard: true
      }
    });
  }

  // Handling Wizard Steps
  switch (state.step) {
    case 'WAITING_MEDIA': {
      if (text === 'تم إرسال الصور ✅') {
        if (!state.trade.images.length) {
          return tg('sendMessage', {
            chat_id: chatId,
            text: '⚠️ لم ترسل أي صورة بعد! أرسل صورة واحدة على الأقل للصفقة من الألبوم.'
          });
        }
        state.step = 'WAITING_DEPOSIT';
        return tg('sendMessage', {
          chat_id: chatId,
          text: `💰 **الخطوة 2 من 5: ما هو مبلغ الإيداع؟**\n\nاختر من الأزرار السريعة أو اكتب المبلغ يدوياً (مثال: \`Deposit: $500\`):`,
          parse_mode: 'Markdown',
          reply_markup: {
            keyboard: [
              [{ text: 'Deposit: $100' }, { text: 'Deposit: $200' }],
              [{ text: 'Deposit: $430' }, { text: 'Deposit: $500' }],
              [{ text: 'Starting: $100+' }, { text: 'Deposit: $1,000' }],
              [{ text: 'إلغاء ❌' }]
            ],
            resize_keyboard: true
          }
        });
      }
      break;
    }

    case 'WAITING_DEPOSIT': {
      state.trade.deposit = text.startsWith('Deposit:') || text.startsWith('Starting:') ? text : `Deposit: ${text}`;
      state.step = 'WAITING_PROFIT';
      return tg('sendMessage', {
        chat_id: chatId,
        text: `🚀 **الخطوة 3 من 5: ما هو مبلغ الربح الصافي؟**\n\nاختر من الأزرار السريعة أو اكتب أي رقم (مثال: \`+$4,500\`):`,
        parse_mode: 'Markdown',
        reply_markup: {
          keyboard: [
            [{ text: '+$1,500' }, { text: '+$3,000' }],
            [{ text: '+$5,700' }, { text: '+$16,000' }],
            [{ text: '+$1,700' }, { text: '+$25,000' }],
            [{ text: 'إلغاء ❌' }]
          ],
          resize_keyboard: true
        }
      });
    }

    case 'WAITING_PROFIT': {
      state.trade.profit = text.startsWith('+') || text.startsWith('$') ? text : `+${text}`;
      state.step = 'WAITING_BADGE';
      return tg('sendMessage', {
        chat_id: chatId,
        text: `🏷️ **الخطوة 4 من 5: اختر شارة المنشور (Badge):**`,
        parse_mode: 'Markdown',
        reply_markup: {
          keyboard: [
            [{ text: 'RECORD PROFIT ⚡' }, { text: '11X RETURN 🎯' }],
            [{ text: '15X RETURN 🚀' }, { text: 'TIERS OPEN 💼' }],
            [{ text: 'NEW TRADE 📈' }, { text: 'LIVE PROOF 💎' }],
            [{ text: 'إلغاء ❌' }]
          ],
          resize_keyboard: true
        }
      });
    }

    case 'WAITING_BADGE': {
      state.trade.badge = text;
      state.trade.badge_type = (text.includes('TIERS') || text.includes('11X')) ? 'gold' : 'neon';
      state.step = 'WAITING_DESC';
      return tg('sendMessage', {
        chat_id: chatId,
        text: `📝 **الخطوة 5 من 5: اكتب وصفاً للصفقة**\n\nأرسل جملة توضيحية للصفقة، أو اضغط **[ تخطي ⏭️ ]**:`,
        parse_mode: 'Markdown',
        reply_markup: {
          keyboard: [
            [{ text: 'تخطي ⏭️' }],
            [{ text: 'إلغاء ❌' }]
          ],
          resize_keyboard: true
        }
      });
    }

    case 'WAITING_DESC': {
      if (text !== 'تخطي ⏭️') {
        state.trade.desc = text;
      } else {
        state.trade.desc = `Live trade execution on Gold (XAUUSD). Net Profit: ${state.trade.profit}. Strict risk management.`;
      }

      state.step = 'CONFIRM';
      const preview = `🔍 **معاينة المنشور قبل الرفع للموقع:**\n\n` +
        `💰 الإيداع: *${state.trade.deposit}*\n` +
        `🚀 الربح: *${state.trade.profit}*\n` +
        `🏷️ الشارة: *${state.trade.badge}*\n` +
        `📸 عدد الصور/الفيديوهات: *${state.trade.images.length}*\n` +
        `📝 الوصف: _${state.trade.desc}_\n\n` +
        `هل تريد نشر هذا المنشور الآن في المركز الأول على موقعك؟`;

      return tg('sendMessage', {
        chat_id: chatId,
        text: preview,
        parse_mode: 'Markdown',
        reply_markup: {
          keyboard: [
            [{ text: '🚀 تأكيد ونشر على الموقع الآن' }],
            [{ text: 'إلغاء ❌' }]
          ],
          resize_keyboard: true
        }
      });
    }

    case 'CONFIRM': {
      if (text === '🚀 تأكيد ونشر على الموقع الآن') {
        await tg('sendMessage', { chat_id: chatId, text: '⏳ جاري النشر ورفع الصفقة إلى موقعك...' });

        const now = new Date();
        const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

        const payload = {
          published_date: dateStr,
          badge_text: state.trade.badge,
          badge_type: state.trade.badge_type,
          deposit_amount: state.trade.deposit,
          profit_amount: state.trade.profit,
          description: state.trade.desc,
          tags: ['#Forex', '#Gold', '#XAUUSD', '#Profits'],
          tweet_url: state.trade.tweet_url,
          profit_split: state.trade.split,
          images: state.trade.images,
          is_active: true,
          created_at: now.toISOString()
        };

        const success = await insertSupabaseTrade(payload);
        resetState(chatId);

        if (success) {
          return tg('sendMessage', {
            chat_id: chatId,
            text: `🎉 **مبروك! تم نشر الصفقة بنجاح على موقعك!** 🚀\n\nلقد أخذت المركز الأول مباشرة قبل كل المنشورات القديمة.\n\n🔗 تفقدها الآن: https://hntsb15.github.io/seifeddine-boumaza/#results`,
            parse_mode: 'Markdown',
            reply_markup: getMainMenuKeyboard()
          });
        } else {
          return tg('sendMessage', {
            chat_id: chatId,
            text: `⚠️ حدث خطأ أثناء النشر في Supabase.\nتأكد من تطبيق كود الصلاحيات في SQL Editor لمرة واحدة.`,
            reply_markup: getMainMenuKeyboard()
          });
        }
      }
      break;
    }

    default: {
      // If user typed random text while IDLE, guide them nicely
      return tg('sendMessage', {
        chat_id: chatId,
        text: `💡 أهلاً بك! لنشر صفقة جديدة اضغط على **[ ➕ نشر صفقة جديدة 🚀 ]**، أو أرسل صورة الصفقة مباشرة من ألبوم هاتفك!`,
        parse_mode: 'Markdown',
        reply_markup: getMainMenuKeyboard()
      });
    }
  }
}

// Handle Incoming Photos and Videos
async function handleMedia(msg) {
  const chatId = msg.chat.id;
  if (!userStates[chatId]) resetState(chatId);
  const state = userStates[chatId];

  // Auto-switch to WAITING_MEDIA if user directly sent media
  if (state.step === 'IDLE') {
    state.step = 'WAITING_MEDIA';
  }

  if (state.step === 'WAITING_MEDIA') {
    await tg('sendChatAction', { chat_id: chatId, action: 'upload_photo' });

    let fileId = null;
    if (msg.photo && msg.photo.length) {
      fileId = msg.photo[msg.photo.length - 1].file_id;
    } else if (msg.video) {
      fileId = msg.video.file_id;
    } else if (msg.document && msg.document.mime_type && msg.document.mime_type.startsWith('image/')) {
      fileId = msg.document.file_id;
    }

    if (!fileId) return;

    const url = await processTelegramFile(fileId);
    if (url) {
      state.trade.images.push(url);
      await tg('sendMessage', {
        chat_id: chatId,
        text: `✅ تم استلام الصورة رقم (${state.trade.images.length}/4) بنجاح!\n\nأرسل صورة أخرى، أو اضغط زر **[ تم إرسال الصور ✅ ]** للمتابعة.`,
        reply_markup: {
          keyboard: [
            [{ text: 'تم إرسال الصور ✅' }],
            [{ text: 'إلغاء ❌' }]
          ],
          resize_keyboard: true
        }
      });
    }
  }
}

// Handle Callback Queries (Delete buttons)
async function handleCallbackQuery(cq) {
  const chatId = cq.message.chat.id;
  const data = cq.data || '';

  if (data.startsWith('del_')) {
    const tradeId = data.replace('del_', '');
    await tg('answerCallbackQuery', { callback_query_id: cq.id, text: 'جاري الحذف...' });

    const ok = await deleteSupabaseTrade(tradeId);
    if (ok) {
      await tg('editMessageText', {
        chat_id: chatId,
        message_id: cq.message.message_id,
        text: `🗑️ **تم حذف هذا المنشور بنجاح واختفى من الموقع فوراً!** ✅`,
        parse_mode: 'Markdown'
      });
    } else {
      await tg('sendMessage', {
        chat_id: chatId,
        text: `⚠️ تعذر حذف المنشور. تحقق من صلاحية DELETE في Supabase.`
      });
    }
  }
}

// Long Polling Loop
let lastUpdateId = 0;
let isPolling = false;

async function pollUpdates() {
  if (isPolling) return;
  isPolling = true;

  try {
    const res = await tg('getUpdates', {
      offset: lastUpdateId + 1,
      timeout: 20
    });

    if (res.ok && Array.isArray(res.result)) {
      for (const update of res.result) {
        lastUpdateId = update.update_id;

        if (update.message) {
          if (update.message.photo || update.message.video) {
            await handleMedia(update.message);
          } else if (update.message.text) {
            await handleMessage(update.message);
          }
        } else if (update.callback_query) {
          await handleCallbackQuery(update.callback_query);
        }
      }
    }
  } catch (err) {
    console.error('Polling error:', err.message);
  } finally {
    isPolling = false;
    setTimeout(pollUpdates, 500);
  }
}

// Catch uncaught exceptions to ensure the bot NEVER crashes
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err.message);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
});

console.log('🤖 Telegram Bot is running...');
pollUpdates();
