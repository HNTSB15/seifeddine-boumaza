/**
 * ==============================================================================
 * 🤖 ULTRA-FAST TELEGRAM BOT CONTROLLER FOR SAIFEDDINE BOUMAZA TRADES
 * Bot Username: @HNTSB15_trades_bot
 * Owner Chat ID: 5513814495 (@HNTSB15)
 * ==============================================================================
 */

const BOT_TOKEN = '8685200299:AAG2nR9wmeskmHH3ZHS7NWSTYANZcRUskQo';
const OWNER_ID = 5513814495; // Saifeddine Boumaza
const SUPABASE_URL = 'https://kbioxkoifvyivhkzbxke.supabase.co';
const SUPABASE_KEY = 'sb_publishable_TXezItY2oN4gFgCxDLqZPw_B_ormkoG';

// In-memory conversation state tracking per user
const userStates = {};

// Helper: Ultra-fast native fetch caller to Telegram API with no socket hangs
async function tg(method, body = {}) {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 25000);

    const res = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    return await res.json();
  } catch (err) {
    // Only log real errors (ignore aborts)
    if (err.name !== 'AbortError') {
      console.error(`TG API error [${method}]:`, err.message);
    }
    return { ok: false };
  }
}

// Helper: Upload file buffer to Catbox CDN with fallback
async function uploadToCatbox(fileBuffer, fileName = 'media.jpg') {
  try {
    const form = new FormData();
    form.append('reqtype', 'fileupload');
    const blob = new Blob([fileBuffer]);
    form.append('fileToUpload', blob, fileName);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const res = await fetch('https://catbox.moe/user/api.php', {
      method: 'POST',
      body: form,
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    const url = (await res.text()).trim();
    if (url.startsWith('https://')) return url;
    throw new Error('Upload failed: ' + url);
  } catch (err) {
    console.error('Catbox upload error:', err.message);
    return null;
  }
}

// Helper: Download a file from Telegram and upload to CDN
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
      [{ text: '🗑️ حذف منشور من الموقع' }, { text: '🌐 معاينة الموقع' }]
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

// Helper: Check authorization
function isAuthorized(chatId) {
  return chatId === OWNER_ID;
}

// Handle Incoming Text & Commands
async function handleMessage(msg) {
  const chatId = msg.chat.id;
  const text = (msg.text || '').trim();

  // Security check: Only Saifeddine Boumaza
  if (!isAuthorized(chatId)) {
    return tg('sendMessage', {
      chat_id: chatId,
      text: '🔒 هذا البوت خاص بإدارة موقع الأستاذ سيف الدين بومعزة فقط.'
    });
  }

  if (!userStates[chatId]) resetState(chatId);
  const state = userStates[chatId];

  // Global cancel / restart / start
  if (text === '/start' || text === '/menu' || text === 'إلغاء ❌') {
    resetState(chatId);
    return tg('sendMessage', {
      chat_id: chatId,
      text: `👋 **أهلاً بك يا سيف الدين!** 💼\n\nالبوت الآن فائق السرعة وجاهز لنشر وحذف الصفقات فوراً على موقعك.\n\nاختر من الأزرار أدناه أو أرسل صورة/فيديو مباشرة:`,
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

  // 1. Delete Flow
  if (text === '🗑️ حذف منشور من الموقع' || text === '/list') {
    resetState(chatId);
    await tg('sendMessage', { chat_id: chatId, text: '⏳ جاري جلب المنشورات من موقعك...' });
    const trades = await getSupabaseTrades();
    if (!Array.isArray(trades) || !trades.length) {
      return tg('sendMessage', {
        chat_id: chatId,
        text: '⚠️ لا توجد منشورات حالياً في قاعدة البيانات.',
        reply_markup: getMainMenuKeyboard()
      });
    }

    await tg('sendMessage', {
      chat_id: chatId,
      text: `📋 **المنشورات الحالية على موقعك (${trades.length} منشور):**\nاضغط على زر [حذف 🗑️] أسفل المنشور الذي تريد إزالته:`,
      parse_mode: 'Markdown'
    });

    for (let i = 0; i < trades.length; i++) {
      const t = trades[i];
      const descSnippet = (t.description || '').substring(0, 50);
      const msgText = `📌 **منشور #${i + 1}**\n💰 الإيداع: \`${t.deposit_amount || 'N/A'}\`\n🚀 الربح: \`${t.profit_amount || 'N/A'}\`\n📅 ${t.published_date || ''} | ${t.badge_text || ''}\n📝 ${descSnippet}...`;

      await tg('sendMessage', {
        chat_id: chatId,
        text: msgText,
        parse_mode: 'Markdown',
        reply_markup: {
          inline_keyboard: [
            [{ text: '🗑️ حذف هذا المنشور فوراً من الموقع', callback_data: `del_${t.id}` }]
          ]
        }
      });
    }
    return;
  }

  // 2. Start New Trade
  if (text === '➕ نشر صفقة جديدة 🚀' || text === '/new') {
    resetState(chatId);
    state.step = 'WAITING_MEDIA';
    return tg('sendMessage', {
      chat_id: chatId,
      text: `📸 **الخطوة 1: أرسل صورة أو فيديو الصفقة**\n\nأرسل الآن الصورة أو الفيديو من استوديو هاتفك:`,
      parse_mode: 'Markdown',
      reply_markup: {
        keyboard: [
          [{ text: 'إلغاء ❌' }]
        ],
        resize_keyboard: true
      }
    });
  }

  // Wizard Steps
  switch (state.step) {
    case 'WAITING_MEDIA': {
      if (text === 'تم إرسال الصور ✅' || text === 'متابعة ➡️') {
        if (!state.trade.images.length) {
          return tg('sendMessage', {
            chat_id: chatId,
            text: '⚠️ لم ترسل أي صورة أو فيديو بعد! أرسل وسائط الصفقة أولاً.'
          });
        }
        state.step = 'WAITING_DEPOSIT';
        return askDeposit(chatId);
      }
      break;
    }

    case 'WAITING_DEPOSIT': {
      let dep = text;
      if (!dep.startsWith('Deposit:') && !dep.startsWith('Starting:')) {
        dep = dep.startsWith('$') ? `Deposit: ${dep}` : `Deposit: $${dep}`;
      }
      state.trade.deposit = dep;
      state.step = 'WAITING_PROFIT';
      return askProfit(chatId);
    }

    case 'WAITING_PROFIT': {
      let pft = text;
      if (!pft.startsWith('+')) {
        pft = pft.startsWith('$') ? `+${pft}` : `+$${pft}`;
      }
      state.trade.profit = pft;
      state.step = 'CONFIRM';
      return showConfirm(chatId, state);
    }

    case 'CONFIRM': {
      if (text === '🚀 تأكيد ونشر على الموقع الآن') {
        await tg('sendMessage', { chat_id: chatId, text: '⏳ جاري النشر في المركز الأول على موقعك...' });

        const now = new Date();
        const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

        const payload = {
          published_date: dateStr,
          badge_text: state.trade.badge || 'RECORD PROFIT ⚡',
          badge_type: state.trade.badge_type || 'neon',
          deposit_amount: state.trade.deposit,
          profit_amount: state.trade.profit,
          description: state.trade.desc || `Live trade execution on Gold (XAUUSD). Net Profit: ${state.trade.profit}. Discipline and risk management.`,
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
            text: `🎉 **مبروك! تم نشر الصفقة فوراً على موقعك!** 🚀\n\nلقد أصبحت المنشور الأول في الواجهة.\n\n🔗 تفقدها مباشرة: https://hntsb15.github.io/seifeddine-boumaza/#results`,
            parse_mode: 'Markdown',
            reply_markup: getMainMenuKeyboard()
          });
        } else {
          return tg('sendMessage', {
            chat_id: chatId,
            text: `⚠️ تعذر النشر في Supabase. حاول مجدداً.`,
            reply_markup: getMainMenuKeyboard()
          });
        }
      }
      break;
    }

    default: {
      return tg('sendMessage', {
        chat_id: chatId,
        text: `💡 أهلاً بك! اضغط على **[ ➕ نشر صفقة جديدة 🚀 ]** أو أرسل صورة/فيديو مباشرة من ألبومك!`,
        parse_mode: 'Markdown',
        reply_markup: getMainMenuKeyboard()
      });
    }
  }
}

// Ask Deposit helper
function askDeposit(chatId) {
  return tg('sendMessage', {
    chat_id: chatId,
    text: `💰 **ما هو مبلغ الإيداع؟**\n\nاضغط زراً سريعاً أو اكتب الرقم مباشرة (مثال: \`500\` أو \`$430\`):`,
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

// Ask Profit helper
function askProfit(chatId) {
  return tg('sendMessage', {
    chat_id: chatId,
    text: `🚀 **ما هو مبلغ الربح الصافي؟**\n\nاضغط زراً سريعاً أو اكتب الرقم مباشرة (مثال: \`5700\` أو \`+$16,000\`):`,
    parse_mode: 'Markdown',
    reply_markup: {
      keyboard: [
        [{ text: '+$1,500' }, { text: '+$1,700' }],
        [{ text: '+$5,700' }, { text: '+$16,000' }],
        [{ text: '+$25,000' }, { text: '+$3,000' }],
        [{ text: 'إلغاء ❌' }]
      ],
      resize_keyboard: true
    }
  });
}

// Show Confirm helper
function showConfirm(chatId, state) {
  const preview = `🔍 **معاينة المنشور قبل الرفع للموقع:**\n\n` +
    `💰 الإيداع: *${state.trade.deposit}*\n` +
    `🚀 الربح: *${state.trade.profit}*\n` +
    `🏷️ الشارة: *${state.trade.badge}*\n` +
    `📸 عدد الوسائط: *${state.trade.images.length}*\n\n` +
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

// Handle Incoming Photos and Videos
async function handleMedia(msg) {
  const chatId = msg.chat.id;
  if (!isAuthorized(chatId)) return;

  if (!userStates[chatId]) resetState(chatId);
  const state = userStates[chatId];

  // Fast chat action acknowledgement (< 200ms)
  tg('sendChatAction', { chat_id: chatId, action: 'upload_photo' });

  let fileId = null;
  if (msg.photo && msg.photo.length) {
    fileId = msg.photo[msg.photo.length - 1].file_id;
  } else if (msg.video) {
    fileId = msg.video.file_id;
  } else if (msg.document && msg.document.mime_type && (msg.document.mime_type.startsWith('image/') || msg.document.mime_type.startsWith('video/'))) {
    fileId = msg.document.file_id;
  }

  if (!fileId) return;

  // Check if caption contains quick deposit + profit (e.g. "500 5700")
  const caption = (msg.caption || '').trim();
  const matchNumbers = caption.match(/\$?([0-9,]+)\s+\+?\$?([0-9,]+)/);

  // Send fast progress message
  const waitMsg = await tg('sendMessage', {
    chat_id: chatId,
    text: '⚡ تم استلام الوسائط، جاري المعالجة السريعة...'
  });

  const url = await processTelegramFile(fileId);
  if (url) {
    state.trade.images.push(url);

    // If caption had deposit & profit, auto-fill and jump straight to confirm!
    if (matchNumbers) {
      state.trade.deposit = `Deposit: $${matchNumbers[1]}`;
      state.trade.profit = `+$${matchNumbers[2]}`;
      state.step = 'CONFIRM';
      return showConfirm(chatId, state);
    }

    state.step = 'WAITING_DEPOSIT';
    await tg('sendMessage', {
      chat_id: chatId,
      text: `✅ **تم استلام الصورة/الفيديو بنجاح!** 🚀`,
      parse_mode: 'Markdown'
    });
    return askDeposit(chatId);
  } else {
    return tg('sendMessage', {
      chat_id: chatId,
      text: '⚠️ تعذر رفع الوسائط، يرجى المحاولة مجدداً.'
    });
  }
}

// Handle Callback Queries (Delete buttons)
async function handleCallbackQuery(cq) {
  const chatId = cq.message.chat.id;
  if (!isAuthorized(chatId)) return;

  const data = cq.data || '';

  if (data.startsWith('del_')) {
    const tradeId = data.replace('del_', '');
    tg('answerCallbackQuery', { callback_query_id: cq.id, text: '⏳ جاري الحذف...' });

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
        text: `⚠️ تعذر حذف المنشور. تحقق من الاتصال.`
      });
    }
  }
}

// Ultra-fast Short Polling Loop (5s poll, 0 socket hang up)
let lastUpdateId = 0;
let isPolling = false;

async function pollUpdates() {
  if (isPolling) return;
  isPolling = true;

  try {
    const res = await tg('getUpdates', {
      offset: lastUpdateId + 1,
      timeout: 5,
      limit: 10
    });

    if (res.ok && Array.isArray(res.result)) {
      for (const update of res.result) {
        lastUpdateId = update.update_id;

        if (update.message) {
          if (update.message.photo || update.message.video || update.message.document) {
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
    setTimeout(pollUpdates, 300);
  }
}

// Global safety error catchers
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err.message);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
});

console.log('⚡ Ultra-fast Telegram Bot is running...');
pollUpdates();
