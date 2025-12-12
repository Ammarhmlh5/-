import { useState, useRef, useEffect } from 'react';
import { Send, Bot, User, Loader2, Trash2 } from 'lucide-react';
import Button from '../components/Button';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export default function AIChat() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      role: 'assistant',
      content: 'مرحباً! أنا مساعد الطيار الآلي لتربية النحل. كيف يمكنني مساعدتك اليوم؟',
      timestamp: new Date(),
    },
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    setTimeout(() => {
      const aiResponse: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: getAIResponse(input),
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, aiResponse]);
      setIsLoading(false);
    }, 1000);
  };

  const getAIResponse = (question: string): string => {
    const lowerQuestion = question.toLowerCase();

    if (lowerQuestion.includes('نحل') || lowerQuestion.includes('خلية') || lowerQuestion.includes('عسل')) {
      return 'بناءً على سؤالك عن النحل، إليك بعض النصائح:\n\n• افحص الخلايا بانتظام كل 7-10 أيام\n• تأكد من وجود الملكة وأنها تضع البيض\n• راقب علامات الأمراض والآفات\n• وفر مصادر مياه نظيفة للنحل\n• احرص على توفير مصادر رحيق متنوعة';
    }

    if (lowerQuestion.includes('مرض') || lowerQuestion.includes('فاروا') || lowerQuestion.includes('علاج')) {
      return 'بالنسبة للأمراض والآفات:\n\n• فحص دوري للكشف المبكر\n• استخدام المنتجات العضوية المعتمدة\n• الحفاظ على نظافة الخلايا\n• عزل الخلايا المصابة\n• استشارة متخصص إذا لزم الأمر';
    }

    if (lowerQuestion.includes('إنتاج') || lowerQuestion.includes('محصول') || lowerQuestion.includes('موسم')) {
      return 'لزيادة الإنتاج:\n\n• تأكد من قوة الطوائف قبل موسم الفيض\n• أضف أقراص عسل إضافية عند الحاجة\n• راقب المحاصيل المزهرة في منطقتك\n• احتفظ بسجلات الإنتاج لكل خلية\n• وفر التغذية التكميلية عند الحاجة';
    }

    if (lowerQuestion.includes('ملكة') || lowerQuestion.includes('تلقيح') || lowerQuestion.includes('تكاثر')) {
      return 'بخصوص الملكات:\n\n• استبدال الملكات كل 2-3 سنوات\n• مراقبة جودة البيض ونمط وضعه\n• تجهيز خلايا النواة للطوارئ\n• التأكد من قبول الملكة الجديدة\n• توثيق نسب الملكات عالية الإنتاج';
    }

    return 'شكراً لسؤالك! أنا هنا لمساعدتك في إدارة المنحل. يمكنك سؤالي عن:\n\n• صحة النحل والأمراض\n• زيادة الإنتاجية\n• رعاية الملكات\n• مواسم الفيض والرحيق\n• إدارة الخلايا\n\nما الذي تود معرفته؟';
  };

  const clearChat = () => {
    setMessages([
      {
        id: '1',
        role: 'assistant',
        content: 'مرحباً! أنا مساعد الطيار الآلي لتربية النحل. كيف يمكنني مساعدتك اليوم؟',
        timestamp: new Date(),
      },
    ]);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)]">
      <div className="bg-white border-b px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 sm:gap-3 min-w-0">
          <div className="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-amber-500 to-orange-500 rounded-xl flex items-center justify-center flex-shrink-0">
            <Bot className="w-5 h-5 sm:w-6 sm:h-6 text-white" />
          </div>
          <div className="min-w-0">
            <h1 className="text-base sm:text-xl font-bold text-gray-900 truncate">الطيار الآلي</h1>
            <p className="text-xs sm:text-sm text-gray-500 truncate hidden sm:block">مساعدك الذكي في تربية النحل</p>
          </div>
        </div>
        <Button variant="ghost" onClick={clearChat} size="sm" className="flex-shrink-0">
          <Trash2 className="w-4 h-4" />
          <span className="hidden sm:inline sm:mr-2">مسح</span>
        </Button>
      </div>

      <div className="flex-1 overflow-y-auto p-3 sm:p-6 bg-gray-50">
        <div className="max-w-4xl mx-auto space-y-3 sm:space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex gap-2 sm:gap-3 ${
                message.role === 'user' ? 'flex-row-reverse' : 'flex-row'
              }`}
            >
              <div
                className={`w-8 h-8 sm:w-10 sm:h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                  message.role === 'user'
                    ? 'bg-blue-500'
                    : 'bg-gradient-to-br from-amber-500 to-orange-500'
                }`}
              >
                {message.role === 'user' ? (
                  <User className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
                ) : (
                  <Bot className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
                )}
              </div>
              <div
                className={`flex-1 max-w-[85%] sm:max-w-3xl ${
                  message.role === 'user' ? 'text-right' : 'text-right'
                }`}
              >
                <div
                  className={`rounded-2xl px-3 py-2 sm:px-4 sm:py-3 inline-block ${
                    message.role === 'user'
                      ? 'bg-blue-500 text-white'
                      : 'bg-white border border-gray-200 text-gray-900'
                  }`}
                >
                  <p className="whitespace-pre-wrap text-sm sm:text-base">{message.content}</p>
                </div>
                <p className="text-xs text-gray-400 mt-1 px-2">
                  {message.timestamp.toLocaleTimeString('ar-SA', {
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
            </div>
          ))}

          {isLoading && (
            <div className="flex gap-2 sm:gap-3">
              <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-gradient-to-br from-amber-500 to-orange-500 flex items-center justify-center flex-shrink-0">
                <Bot className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
              </div>
              <div className="bg-white border border-gray-200 rounded-2xl px-3 py-2 sm:px-4 sm:py-3">
                <Loader2 className="w-4 h-4 sm:w-5 sm:h-5 text-gray-400 animate-spin" />
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>
      </div>

      <div className="bg-white border-t p-3 sm:p-4">
        <div className="max-w-4xl mx-auto">
          <div className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSend()}
              placeholder="اكتب سؤالك هنا..."
              className="flex-1 px-3 py-2 sm:px-4 sm:py-3 text-sm sm:text-base border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent text-right"
              disabled={isLoading}
            />
            <Button
              onClick={handleSend}
              disabled={!input.trim() || isLoading}
              className="px-4 sm:px-6"
              size="sm"
            >
              {isLoading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <>
                  <Send className="w-4 h-4 sm:w-5 sm:h-5 sm:ml-2" />
                  <span className="hidden sm:inline">إرسال</span>
                </>
              )}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
