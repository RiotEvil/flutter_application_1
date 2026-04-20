import 'package:flutter/material.dart';

import 'constants.dart';

class SubscriptionTexts {
  SubscriptionTexts._();

  static String _lang(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase();
  }

  static String _pick(BuildContext context, Map<String, String> values) {
    final code = _lang(context);
    return values[code] ?? values['en']!;
  }

  static String planName(BuildContext context, AppPlan plan) {
    switch (plan) {
      case AppPlan.free:
        return _pick(context, {
          'en': 'Free',
          'ru': 'Бесплатный',
          'pl': 'Bezpłatny',
          'pt': 'Gratuito',
          'tr': 'Ucretsiz',
          'zh': '免费',
          'es': 'Gratis',
          'it': 'Gratis',
          'de': 'Kostenlos',
        });
      case AppPlan.pro:
        return 'Pro';
      case AppPlan.business:
        return _pick(context, {
          'en': 'Business',
          'ru': 'Бизнес',
          'pl': 'Business',
          'pt': 'Business',
          'tr': 'Business',
          'zh': '商业版',
          'es': 'Business',
          'it': 'Business',
          'de': 'Business',
        });
    }
  }

  static String planStatus(BuildContext context, PlanStatus status) {
    switch (status) {
      case PlanStatus.inactive:
        return _pick(context, {
          'en': 'Inactive',
          'ru': 'Неактивен',
          'pl': 'Nieaktywny',
          'pt': 'Inativo',
          'tr': 'Pasif',
          'zh': '未激活',
          'es': 'Inactivo',
          'it': 'Inattivo',
          'de': 'Inaktiv',
        });
      case PlanStatus.active:
        return _pick(context, {
          'en': 'Active',
          'ru': 'Активен',
          'pl': 'Aktywny',
          'pt': 'Ativo',
          'tr': 'Aktif',
          'zh': '已激活',
          'es': 'Activo',
          'it': 'Attivo',
          'de': 'Aktiv',
        });
      case PlanStatus.trial:
        return _pick(context, {
          'en': 'Trial',
          'ru': 'Пробный',
          'pl': 'Okres probny',
          'pt': 'Teste',
          'tr': 'Deneme',
          'zh': '试用',
          'es': 'Prueba',
          'it': 'Prova',
          'de': 'Testphase',
        });
      case PlanStatus.grace:
        return _pick(context, {
          'en': 'Grace period',
          'ru': 'Льготный период',
          'pl': 'Okres karencji',
          'pt': 'Periodo de graca',
          'tr': 'Ek sure',
          'zh': '宽限期',
          'es': 'Periodo de gracia',
          'it': 'Periodo di tolleranza',
          'de': 'Kulanzzeit',
        });
    }
  }

  static String plansAndPricing(BuildContext context) {
    return _pick(context, {
      'en': 'Plans and pricing',
      'ru': 'Тарифы и цены',
      'pl': 'Plany i ceny',
      'pt': 'Planos e precos',
      'tr': 'Planlar ve fiyatlar',
      'zh': '套餐与价格',
      'es': 'Planes y precios',
      'it': 'Piani e prezzi',
      'de': 'Tarife und Preise',
    });
  }

  static String releaseSectionTitle(BuildContext context) {
    return _pick(context, {
      'en': 'RELEASE',
      'ru': 'РЕЛИЗ',
      'pl': 'WYDANIE',
      'pt': 'LANCAMENTO',
      'tr': 'SURUM',
      'zh': '发布',
      'es': 'LANZAMIENTO',
      'it': 'RILASCIO',
      'de': 'RELEASE',
    });
  }

  static String legalDocumentsTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Legal documents',
      'ru': 'Юридические документы',
      'pl': 'Dokumenty prawne',
      'pt': 'Documentos legais',
      'tr': 'Yasal belgeler',
      'zh': '法律文件',
      'es': 'Documentos legales',
      'it': 'Documenti legali',
      'de': 'Rechtliche Dokumente',
    });
  }

  static String legalDocumentsSubtitle(BuildContext context) {
    return _pick(context, {
      'en': 'Draft privacy policy and terms prepared for store release.',
      'ru':
          'Черновики политики конфиденциальности и условий подготовлены для публикации в сторе.',
      'pl':
          'Szkice polityki prywatnosci i regulaminu przygotowane do publikacji w sklepie.',
      'pt':
          'Rascunhos de politica de privacidade e termos preparados para lancamento na loja.',
      'tr':
          'Gizlilik politikasi ve kosullar taslagi magaza yayinina hazirlandi.',
      'zh': '隐私政策与条款草案已为商店发布准备就绪。',
      'es':
          'Borradores de politica de privacidad y terminos listos para lanzamiento en la tienda.',
      'it':
          'Bozze di privacy policy e termini pronte per la pubblicazione sullo store.',
      'de':
          'Entwurfe fur Datenschutzrichtlinie und Nutzungsbedingungen fur den Store-Release vorbereitet.',
    });
  }

  static String currentPlanLine(
    BuildContext context,
    AppPlan plan,
    PlanStatus status,
  ) {
    final prefix = _pick(context, {
      'en': 'Current',
      'ru': 'Текущий',
      'pl': 'Aktualny',
      'pt': 'Atual',
      'tr': 'Mevcut',
      'zh': '当前',
      'es': 'Actual',
      'it': 'Corrente',
      'de': 'Aktuell',
    });
    return '$prefix: ${planName(context, plan)} · ${planStatus(context, status)}';
  }

  static String requiredPlan(BuildContext context, AppPlan plan) {
    final prefix = _pick(context, {
      'en': 'Required plan',
      'ru': 'Нужен тариф',
      'pl': 'Wymagany plan',
      'pt': 'Plano necessario',
      'tr': 'Gerekli plan',
      'zh': '所需套餐',
      'es': 'Plan requerido',
      'it': 'Piano richiesto',
      'de': 'Erforderlicher Tarif',
    });
    return '$prefix: ${planName(context, plan)}';
  }

  static String viewPlans(BuildContext context) {
    return _pick(context, {
      'en': 'View plans',
      'ru': 'Смотреть тарифы',
      'pl': 'Zobacz plany',
      'pt': 'Ver planos',
      'tr': 'Planlari gor',
      'zh': '查看套餐',
      'es': 'Ver planes',
      'it': 'Vedi piani',
      'de': 'Tarife ansehen',
    });
  }

  static String businessPlanRequiredTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Business plan required',
      'ru': 'Требуется тариф Бизнес',
      'pl': 'Wymagany plan Business',
      'pt': 'Plano Business necessario',
      'tr': 'Business plani gerekli',
      'zh': '需要商业版套餐',
      'es': 'Se requiere plan Business',
      'it': 'Piano Business richiesto',
      'de': 'Business-Tarif erforderlich',
    });
  }

  static String teamWorkspaceBusinessMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Team mode, roles and shared workspace are available on the Business plan.',
      'ru':
          'Командный режим, роли и общее рабочее пространство доступны на тарифе Бизнес.',
      'pl':
          'Tryb zespolowy, role i wspolna przestrzen robocza sa dostepne w planie Business.',
      'pt':
          'Modo de equipe, funcoes e espaco de trabalho compartilhado estao disponiveis no plano Business.',
      'tr':
          'Ekip modu, roller ve paylasilan calisma alani Business planinda mevcuttur.',
      'zh': '团队模式、角色与共享工作区仅在商业版套餐中可用。',
      'es':
          'El modo equipo, los roles y el espacio compartido estan disponibles en el plan Business.',
      'it':
          'Modalita team, ruoli e workspace condiviso sono disponibili nel piano Business.',
      'de':
          'Teammodus, Rollen und gemeinsamer Arbeitsbereich sind im Business-Tarif verfugbar.',
    });
  }

  static String crmProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'CRM campaigns require Pro',
      'ru': 'CRM-кампании требуют Pro',
      'pl': 'Kampanie CRM wymagaja Pro',
      'pt': 'Campanhas CRM exigem Pro',
      'tr': 'CRM kampanyalari Pro gerektirir',
      'zh': 'CRM 活动需要 Pro',
      'es': 'Las campanas CRM requieren Pro',
      'it': 'Le campagne CRM richiedono Pro',
      'de': 'CRM-Kampagnen erfordern Pro',
    });
  }

  static String crmProMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Upgrade to Pro to use client segments, bulk reminders and campaign history.',
      'ru':
          'Перейдите на Pro, чтобы использовать сегменты клиентов, массовые напоминания и историю кампаний.',
      'pl':
          'Przejdz na Pro, aby korzystac z segmentow klientow, masowych przypomnien i historii kampanii.',
      'pt':
          'Atualize para Pro para usar segmentos de clientes, lembretes em massa e historico de campanhas.',
      'tr':
          'Musteri segmentlerini, toplu hatirlaticilari ve kampanya gecmisini kullanmak icin Pro\'ya gecin.',
      'zh': '升级到 Pro 以使用客户分群、批量提醒和活动历史。',
      'es':
          'Actualiza a Pro para usar segmentos de clientes, recordatorios masivos e historial de campanas.',
      'it':
          'Passa a Pro per usare segmenti clienti, promemoria di massa e storico campagne.',
      'de':
          'Upgrade auf Pro, um Kundensegmente, Massen-Erinnerungen und Kampagnenverlauf zu nutzen.',
    });
  }

  static String marketingProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Marketing tools require Pro',
      'ru': 'Маркетинговые инструменты требуют Pro',
      'pl': 'Narzedia marketingowe wymagaja Pro',
      'pt': 'Ferramentas de marketing exigem Pro',
      'tr': 'Pazarlama araclari Pro gerektirir',
      'zh': '营销工具需要 Pro',
      'es': 'Las herramientas de marketing requieren Pro',
      'it': 'Gli strumenti di marketing richiedono Pro',
      'de': 'Marketing-Tools erfordern Pro',
    });
  }

  static String marketingProMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Upgrade to Pro to access reactivation lists, marketing insights and CRM outreach tools.',
      'ru':
          'Перейдите на Pro, чтобы получить доступ к спискам реактивации, маркетинговой аналитике и CRM-инструментам.',
      'pl':
          'Przejdz na Pro, aby uzyskac dostep do list reaktywacji, analityki marketingowej i narzedzi CRM.',
      'pt':
          'Atualize para Pro para acessar listas de reativacao, insights de marketing e ferramentas de CRM.',
      'tr':
          'Yeniden etkinlestirme listelerine, pazarlama analizlerine ve CRM araclarina erismek icin Pro\'ya gecin.',
      'zh': '升级到 Pro 以访问召回名单、营销洞察和 CRM 工具。',
      'es':
          'Actualiza a Pro para acceder a listas de reactivacion, analitica de marketing y herramientas CRM.',
      'it':
          'Passa a Pro per accedere a liste di riattivazione, insight marketing e strumenti CRM.',
      'de':
          'Upgrade auf Pro fur Reaktivierungslisten, Marketing-Insights und CRM-Tools.',
    });
  }

  static String bookingProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Online booking requires Pro',
      'ru': 'Онлайн-запись требует Pro',
      'pl': 'Rezerwacje online wymagaja Pro',
      'pt': 'Agendamento online exige Pro',
      'tr': 'Cevrimici rezervasyon Pro gerektirir',
      'zh': '在线预约需要 Pro',
      'es': 'Las reservas online requieren Pro',
      'it': 'Le prenotazioni online richiedono Pro',
      'de': 'Online-Buchungen erfordern Pro',
    });
  }

  static String bookingProMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Upgrade to Pro to receive booking requests and share your online booking link.',
      'ru':
          'Перейдите на Pro, чтобы получать заявки на запись и делиться ссылкой на онлайн-бронирование.',
      'pl':
          'Przejdz na Pro, aby otrzymywac prosby o rezerwacje i udostepniac link do rezerwacji online.',
      'pt':
          'Atualize para Pro para receber pedidos de agendamento e compartilhar seu link de reservas online.',
      'tr':
          'Rezervasyon talepleri almak ve cevrimici rezervasyon baglantinizi paylasmak icin Pro\'ya gecin.',
      'zh': '升级到 Pro 以接收预约请求并分享在线预约链接。',
      'es':
          'Actualiza a Pro para recibir solicitudes de reserva y compartir tu enlace de reservas online.',
      'it':
          'Passa a Pro per ricevere richieste di prenotazione e condividere il link di booking online.',
      'de':
          'Upgrade auf Pro, um Buchungsanfragen zu erhalten und deinen Online-Buchungslink zu teilen.',
    });
  }

  static String remindersProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Automated reminders require Pro',
      'ru': 'Автоматические напоминания требуют Pro',
      'pl': 'Automatyczne przypomnienia wymagaja Pro',
      'pt': 'Lembretes automaticos exigem Pro',
      'tr': 'Otomatik hatirlaticilar Pro gerektirir',
      'zh': '自动提醒需要 Pro',
      'es': 'Los recordatorios automaticos requieren Pro',
      'it': 'I promemoria automatici richiedono Pro',
      'de': 'Automatische Erinnerungen erfordern Pro',
    });
  }

  static String remindersProMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Upgrade to Pro to schedule automatic appointment reminders for upcoming orders.',
      'ru':
          'Перейдите на Pro, чтобы планировать автоматические напоминания о предстоящих заказах.',
      'pl':
          'Przejdz na Pro, aby planowac automatyczne przypomnienia o nadchodzacych zleceniach.',
      'pt':
          'Atualize para Pro para agendar lembretes automaticos para pedidos futuros.',
      'tr':
          'Yaklasan siparisler icin otomatik randevu hatirlaticilari planlamak uzere Pro\'ya gecin.',
      'zh': '升级到 Pro 以为即将到来的订单安排自动预约提醒。',
      'es':
          'Actualiza a Pro para programar recordatorios automaticos para pedidos proximos.',
      'it':
          'Passa a Pro per programmare promemoria automatici per gli ordini imminenti.',
      'de':
          'Upgrade auf Pro, um automatische Terminerinnerungen fur kommende Auftrage zu planen.',
    });
  }

  static String freeClientLimitTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Free plan client limit reached',
      'ru': 'Достигнут лимит клиентов на Free',
      'pl': 'Osiagnieto limit klientow w planie Free',
      'pt': 'Limite de clientes do plano Free atingido',
      'tr': 'Free plani musteri limitine ulasildi',
      'zh': '已达到免费套餐客户上限',
      'es': 'Se alcanzo el limite de clientes del plan Free',
      'it': 'Raggiunto il limite clienti del piano Free',
      'de': 'Kundenlimit im Free-Tarif erreicht',
    });
  }

  static String freeClientLimitMessage(BuildContext context, int limit) {
    return _pick(context, {
      'en':
          'The Free plan supports up to $limit clients. Upgrade to Pro for unlimited client storage.',
      'ru':
          'Тариф Free поддерживает до $limit клиентов. Перейдите на Pro для неограниченной клиентской базы.',
      'pl':
          'Plan Free obsluguje do $limit klientow. Przejdz na Pro, aby miec nielimitowana baze klientow.',
      'pt':
          'O plano Free suporta ate $limit clientes. Atualize para Pro para clientes ilimitados.',
      'tr':
          'Free plan en fazla $limit musteri destekler. Sinirsiz musteri icin Pro\'ya gecin.',
      'zh': '免费套餐最多支持 $limit 位客户。升级到 Pro 可获得无限客户数。',
      'es':
          'El plan Free admite hasta $limit clientes. Actualiza a Pro para clientes ilimitados.',
      'it':
          'Il piano Free supporta fino a $limit clienti. Passa a Pro per clienti illimitati.',
      'de':
          'Der Free-Tarif unterstutzt bis zu $limit Kunden. Upgrade auf Pro fur unbegrenzte Kunden.',
    });
  }

  static String freeOrderLimitTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Free plan order limit reached',
      'ru': 'Достигнут лимит заказов на Free',
      'pl': 'Osiagnieto limit zlecen w planie Free',
      'pt': 'Limite de pedidos do plano Free atingido',
      'tr': 'Free plani siparis limitine ulasildi',
      'zh': '已达到免费套餐订单上限',
      'es': 'Se alcanzo el limite de pedidos del plan Free',
      'it': 'Raggiunto il limite ordini del piano Free',
      'de': 'Auftragslimit im Free-Tarif erreicht',
    });
  }

  static String freeOrderLimitMessage(BuildContext context, int limit) {
    return _pick(context, {
      'en':
          'The Free plan supports up to $limit active orders per month. Upgrade to Pro for unlimited orders.',
      'ru':
          'Тариф Free поддерживает до $limit активных заказов в месяц. Перейдите на Pro для неограниченных заказов.',
      'pl':
          'Plan Free obsluguje do $limit aktywnych zlecen miesiecznie. Przejdz na Pro dla nielimitowanych zlecen.',
      'pt':
          'O plano Free suporta ate $limit pedidos ativos por mes. Atualize para Pro para pedidos ilimitados.',
      'tr':
          'Free plan ayda en fazla $limit aktif siparis destekler. Sinirsiz siparis icin Pro\'ya gecin.',
      'zh': '免费套餐每月最多支持 $limit 个活跃订单。升级到 Pro 可获得无限订单。',
      'es':
          'El plan Free admite hasta $limit pedidos activos por mes. Actualiza a Pro para pedidos ilimitados.',
      'it':
          'Il piano Free supporta fino a $limit ordini attivi al mese. Passa a Pro per ordini illimitati.',
      'de':
          'Der Free-Tarif unterstutzt bis zu $limit aktive Auftrage pro Monat. Upgrade auf Pro fur unbegrenzte Auftrage.',
    });
  }

  static String chatAttachmentsProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Chat attachments require Pro',
      'ru': 'Вложения в чате требуют Pro',
      'pl': 'Zalaczniki na czacie wymagaja Pro',
      'pt': 'Anexos no chat exigem Pro',
      'tr': 'Sohbet ekleri Pro gerektirir',
      'zh': '聊天附件需要 Pro',
      'es': 'Los adjuntos del chat requieren Pro',
      'it': 'Gli allegati in chat richiedono Pro',
      'de': 'Chat-Anhange erfordern Pro',
    });
  }

  static String chatAttachmentsProMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Upgrade to Pro to send photos and files inside chat across your organization.',
      'ru':
          'Перейдите на Pro, чтобы отправлять фото и файлы в чате внутри вашей организации.',
      'pl':
          'Przejdz na Pro, aby wysylac zdjecia i pliki na czacie w organizacji.',
      'pt':
          'Atualize para Pro para enviar fotos e arquivos no chat da sua organizacao.',
      'tr':
          'Kurulusunuz genelinde sohbette fotograf ve dosya gondermek icin Pro\'ya gecin.',
      'zh': '升级到 Pro 以在组织内聊天中发送照片和文件。',
      'es':
          'Actualiza a Pro para enviar fotos y archivos en el chat de tu organizacion.',
      'it':
          'Passa a Pro per inviare foto e file nella chat della tua organizzazione.',
      'de':
          'Upgrade auf Pro, um Fotos und Dateien im Chat in deiner Organisation zu senden.',
    });
  }

  static String fileSharingProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'File sharing requires Pro',
      'ru': 'Обмен файлами требует Pro',
      'pl': 'Udostepnianie plikow wymaga Pro',
      'pt': 'Compartilhamento de arquivos exige Pro',
      'tr': 'Dosya paylasimi Pro gerektirir',
      'zh': '文件共享需要 Pro',
      'es': 'Compartir archivos requiere Pro',
      'it': 'La condivisione file richiede Pro',
      'de': 'Dateifreigabe erfordert Pro',
    });
  }

  static String fileSharingProMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Upgrade to Pro to share documents, checklists and media files in chat.',
      'ru':
          'Перейдите на Pro, чтобы делиться документами, чек-листами и медиафайлами в чате.',
      'pl':
          'Przejdz na Pro, aby udostepniac dokumenty, checklisty i pliki multimedialne na czacie.',
      'pt':
          'Atualize para Pro para compartilhar documentos, checklists e midia no chat.',
      'tr':
          'Sohbette belge, kontrol listesi ve medya dosyalari paylasmak icin Pro\'ya gecin.',
      'zh': '升级到 Pro 以在聊天中共享文档、清单和媒体文件。',
      'es':
          'Actualiza a Pro para compartir documentos, listas y archivos multimedia en el chat.',
      'it':
          'Passa a Pro per condividere documenti, checklist e file multimediali in chat.',
      'de':
          'Upgrade auf Pro, um Dokumente, Checklisten und Mediendateien im Chat zu teilen.',
    });
  }

  static String statsProTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Advanced analytics require Pro',
      'ru': 'Расширенная аналитика требует Pro',
      'pl': 'Zaawansowana analityka wymaga Pro',
      'pt': 'Analises avancadas exigem Pro',
      'tr': 'Gelismis analizler Pro gerektirir',
      'zh': '高级分析需要 Pro',
      'es': 'La analitica avanzada requiere Pro',
      'it': 'Le analisi avanzate richiedono Pro',
      'de': 'Erweiterte Analysen erfordern Pro',
    });
  }

  static String statsProSubtitle(BuildContext context) {
    return _pick(context, {
      'en':
          'Unlock revenue trends, order history views and business performance insights with Pro or Business.',
      'ru':
          'Откройте тренды выручки, историю заказов и метрики эффективности бизнеса с Pro или Бизнес.',
      'pl':
          'Odblokuj trendy przychodow, historie zlecen i analize efektywnosci z planem Pro lub Business.',
      'pt':
          'Desbloqueie tendencias de receita, historico de pedidos e analise de desempenho com Pro ou Business.',
      'tr':
          'Pro veya Business ile gelir trendlerini, siparis gecmisini ve performans analizini acin.',
      'zh': '使用 Pro 或商业版解锁营收趋势、订单历史和业务表现分析。',
      'es':
          'Desbloquea tendencias de ingresos, historial de pedidos e indicadores de rendimiento con Pro o Business.',
      'it':
          'Sblocca trend ricavi, storico ordini e analisi performance con Pro o Business.',
      'de':
          'Schalte Umsatztrends, Auftragshistorie und Performance-Analysen mit Pro oder Business frei.',
    });
  }

  static String statsUpgradeTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Upgrade for analytics',
      'ru': 'Апгрейд для аналитики',
      'pl': 'Ulepsz do analityki',
      'pt': 'Upgrade para analises',
      'tr': 'Analiz icin yukselt',
      'zh': '升级以使用分析',
      'es': 'Mejorar para analitica',
      'it': 'Upgrade per analisi',
      'de': 'Upgrade fur Analysen',
    });
  }

  static String statsUpgradeMessage(BuildContext context) {
    return _pick(context, {
      'en':
          'Detailed reporting and performance dashboards are included in Pro and Business plans.',
      'ru':
          'Подробные отчеты и дашборды производительности входят в тарифы Pro и Бизнес.',
      'pl':
          'Szczegolowe raporty i pulpity wydajnosci sa dostepne w planach Pro i Business.',
      'pt':
          'Relatorios detalhados e dashboards de desempenho estao incluidos nos planos Pro e Business.',
      'tr':
          'Ayrintili raporlama ve performans panolari Pro ve Business planlarina dahildir.',
      'zh': '详细报表和性能看板包含在 Pro 与商业版套餐中。',
      'es':
          'Los informes detallados y paneles de rendimiento estan incluidos en Pro y Business.',
      'it':
          'Report dettagliati e dashboard performance sono inclusi nei piani Pro e Business.',
      'de':
          'Detaillierte Berichte und Performance-Dashboards sind in Pro- und Business-Tarifen enthalten.',
    });
  }

  static String pricingTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Plans',
      'ru': 'Тарифы',
      'pl': 'Plany',
      'pt': 'Planos',
      'tr': 'Planlar',
      'zh': '套餐',
      'es': 'Planes',
      'it': 'Piani',
      'de': 'Tarife',
    });
  }

  static String pricingIntroTitle(BuildContext context) {
    return _pick(context, {
      'en': 'International pricing baseline',
      'ru': 'Базовая международная тарификация',
      'pl': 'Bazowe ceny miedzynarodowe',
      'pt': 'Base internacional de precos',
      'tr': 'Uluslararasi fiyatlandirma tabani',
      'zh': '国际定价基线',
      'es': 'Base internacional de precios',
      'it': 'Base prezzi internazionale',
      'de': 'Internationale Preisbasis',
    });
  }

  static String pricingIntroBody(BuildContext context) {
    return _pick(context, {
      'en':
          'These plans are prepared as a starting point for Europe-first launch. Store pricing can be localized later for Poland and other markets.',
      'ru':
          'Эти тарифы подготовлены как старт для запуска в Европе. Цены в сторах можно локализовать отдельно для Польши и других рынков.',
      'pl':
          'Te plany sa przygotowane jako punkt startowy dla wdrozenia w Europie. Ceny sklepowe mozna pozniej zlokalizowac dla Polski i innych rynkow.',
      'pt':
          'Esses planos sao um ponto de partida para lancamento na Europa. Os precos da loja podem ser localizados depois para a Polonia e outros mercados.',
      'tr':
          'Bu planlar Avrupa odakli lansman icin baslangic noktasi olarak hazirlandi. Magaza fiyatlari daha sonra Polonya ve diger pazarlar icin yerlestirilebilir.',
      'zh': '这些套餐作为欧洲优先发布的起点，后续可为波兰及其他市场本地化商店价格。',
      'es':
          'Estos planes se prepararon como base para un lanzamiento inicial en Europa. Los precios de tienda se pueden localizar despues para Polonia y otros mercados.',
      'it':
          'Questi piani sono una base per il lancio iniziale in Europa. I prezzi store potranno essere localizzati in seguito per Polonia e altri mercati.',
      'de':
          'Diese Tarife sind als Ausgangspunkt fur einen Europa-Start gedacht. Store-Preise konnen spater fur Polen und andere Markte lokalisiert werden.',
    });
  }

  static String currentBadge(BuildContext context) {
    return _pick(context, {
      'en': 'Current',
      'ru': 'Текущий',
      'pl': 'Aktualny',
      'pt': 'Atual',
      'tr': 'Mevcut',
      'zh': '当前',
      'es': 'Actual',
      'it': 'Corrente',
      'de': 'Aktuell',
    });
  }

  static String recommendedBadge(BuildContext context) {
    return _pick(context, {
      'en': 'Recommended',
      'ru': 'Рекомендуем',
      'pl': 'Polecany',
      'pt': 'Recomendado',
      'tr': 'Onerilen',
      'zh': '推荐',
      'es': 'Recomendado',
      'it': 'Consigliato',
      'de': 'Empfohlen',
    });
  }

  static String planDescription(BuildContext context, AppPlan plan) {
    switch (plan) {
      case AppPlan.free:
        return _pick(context, {
          'en':
              'For solo specialists who want to try the app and keep basic operations in one place.',
          'ru':
              'Для мастеров-одиночек, которые хотят попробовать приложение и вести базовые процессы в одном месте.',
          'pl':
              'Dla samodzielnych specjalistow, ktorzy chca przetestowac aplikacje i prowadzic podstawowe procesy w jednym miejscu.',
          'pt':
              'Para profissionais solo que querem testar o app e manter operacoes basicas em um so lugar.',
          'tr':
              'Uygulamayi denemek ve temel islemleri tek yerde tutmak isteyen tek uzmanlar icin.',
          'zh': '适合想先试用应用、并在一个地方管理基础流程的个人技师。',
          'es':
              'Para especialistas independientes que quieren probar la app y mantener operaciones basicas en un solo lugar.',
          'it':
              'Per professionisti singoli che vogliono provare l\'app e gestire le operazioni base in un unico posto.',
          'de':
              'Fur Einzel-Spezialisten, die die App testen und grundlegende Ablaufe an einem Ort verwalten wollen.',
        });
      case AppPlan.pro:
        return _pick(context, {
          'en':
              'For independent professionals who need full workflows, reminders and reporting.',
          'ru':
              'Для независимых специалистов, которым нужны полные процессы, напоминания и отчетность.',
          'pl':
              'Dla niezaleznych profesjonalistow, ktorzy potrzebuja pelnych procesow, przypomnien i raportowania.',
          'pt':
              'Para profissionais independentes que precisam de fluxos completos, lembretes e relatorios.',
          'tr':
              'Tam is akislarina, hatirlaticilara ve raporlamaya ihtiyac duyan bagimsiz profesyoneller icin.',
          'zh': '适合需要完整流程、提醒和报表的独立专业人士。',
          'es':
              'Para profesionales independientes que necesitan flujos completos, recordatorios e informes.',
          'it':
              'Per professionisti indipendenti che necessitano di flussi completi, promemoria e report.',
          'de':
              'Fur unabhangige Profis, die vollstandige Workflows, Erinnerungen und Reporting benotigen.',
        });
      case AppPlan.business:
        return _pick(context, {
          'en':
              'For studios and teams that need shared access, roles and business control.',
          'ru':
              'Для студий и команд, которым нужны общий доступ, роли и управляемость бизнеса.',
          'pl':
              'Dla studiow i zespolow, ktore potrzebuja wspolnego dostepu, rol i kontroli biznesu.',
          'pt':
              'Para estudios e equipes que precisam de acesso compartilhado, funcoes e controle do negocio.',
          'tr':
              'Paylasimli erisim, roller ve isletme kontrolu gereken studyolar ve ekipler icin.',
          'zh': '适合需要共享访问、角色与业务管控的门店和团队。',
          'es':
              'Para estudios y equipos que necesitan acceso compartido, roles y control del negocio.',
          'it':
              'Per studi e team che necessitano di accesso condiviso, ruoli e controllo del business.',
          'de':
              'Fur Studios und Teams mit Bedarf an gemeinsamem Zugriff, Rollen und Business-Kontrolle.',
        });
    }
  }

  static String planPrice(BuildContext context, AppPlan plan) {
    switch (plan) {
      case AppPlan.free:
        return _pick(context, {
          'en': '€0 / month',
          'ru': '€0 / мес',
          'pl': '€0 / mies.',
          'pt': '€0 / mes',
          'tr': '€0 / ay',
          'zh': '€0 / 月',
          'es': '€0 / mes',
          'it': '€0 / mese',
          'de': '€0 / Monat',
        });
      case AppPlan.pro:
        return _pick(context, {
          'en': '€19 / month',
          'ru': '€19 / мес',
          'pl': '€19 / mies.',
          'pt': '€19 / mes',
          'tr': '€19 / ay',
          'zh': '€19 / 月',
          'es': '€19 / mes',
          'it': '€19 / mese',
          'de': '€19 / Monat',
        });
      case AppPlan.business:
        return _pick(context, {
          'en': '€59 / month',
          'ru': '€59 / мес',
          'pl': '€59 / mies.',
          'pt': '€59 / mes',
          'tr': '€59 / ay',
          'zh': '€59 / 月',
          'es': '€59 / mes',
          'it': '€59 / mese',
          'de': '€59 / Monat',
        });
    }
  }

  static List<String> planFeatures(BuildContext context, AppPlan plan) {
    switch (plan) {
      case AppPlan.free:
        return [
          _pick(context, {
            'en': '1 user',
            'ru': '1 пользователь',
            'pl': '1 uzytkownik',
            'pt': '1 usuario',
            'tr': '1 kullanici',
            'zh': '1 位用户',
            'es': '1 usuario',
            'it': '1 utente',
            'de': '1 Benutzer',
          }),
          _pick(context, {
            'en': 'Up to 100 clients',
            'ru': 'До 100 клиентов',
            'pl': 'Do 100 klientow',
            'pt': 'Ate 100 clientes',
            'tr': '100 musteriye kadar',
            'zh': '最多 100 位客户',
            'es': 'Hasta 100 clientes',
            'it': 'Fino a 100 clienti',
            'de': 'Bis zu 100 Kunden',
          }),
          _pick(context, {
            'en': 'Up to 30 active orders per month',
            'ru': 'До 30 активных заказов в месяц',
            'pl': 'Do 30 aktywnych zlecen miesiecznie',
            'pt': 'Ate 30 pedidos ativos por mes',
            'tr': 'Aylik 30 aktif siparise kadar',
            'zh': '每月最多 30 个活跃订单',
            'es': 'Hasta 30 pedidos activos por mes',
            'it': 'Fino a 30 ordini attivi al mese',
            'de': 'Bis zu 30 aktive Auftrage pro Monat',
          }),
          _pick(context, {
            'en': 'Basic calendar and client cards',
            'ru': 'Базовый календарь и карточки клиентов',
            'pl': 'Podstawowy kalendarz i karty klientow',
            'pt': 'Calendario basico e fichas de clientes',
            'tr': 'Temel takvim ve musteri kartlari',
            'zh': '基础日历与客户卡片',
            'es': 'Calendario basico y fichas de clientes',
            'it': 'Calendario base e schede clienti',
            'de': 'Basis-Kalender und Kundenkarten',
          }),
          _pick(context, {
            'en': 'In-app reminders only',
            'ru': 'Только напоминания внутри приложения',
            'pl': 'Tylko przypomnienia w aplikacji',
            'pt': 'Apenas lembretes no app',
            'tr': 'Yalnizca uygulama ici hatirlaticilar',
            'zh': '仅应用内提醒',
            'es': 'Solo recordatorios en la app',
            'it': 'Solo promemoria in-app',
            'de': 'Nur In-App-Erinnerungen',
          }),
          _pick(context, {
            'en': 'Limited file attachments',
            'ru': 'Ограниченные вложения файлов',
            'pl': 'Ograniczone zalaczniki plikow',
            'pt': 'Anexos de arquivos limitados',
            'tr': 'Sinirli dosya ekleri',
            'zh': '有限文件附件',
            'es': 'Adjuntos limitados',
            'it': 'Allegati file limitati',
            'de': 'Begrenzte Dateianhange',
          }),
        ];
      case AppPlan.pro:
        return [
          _pick(context, {
            'en': '1 user',
            'ru': '1 пользователь',
            'pl': '1 uzytkownik',
            'pt': '1 usuario',
            'tr': '1 kullanici',
            'zh': '1 位用户',
            'es': '1 usuario',
            'it': '1 utente',
            'de': '1 Benutzer',
          }),
          _pick(context, {
            'en': 'Unlimited clients and orders',
            'ru': 'Безлимит клиентов и заказов',
            'pl': 'Nielimitowana liczba klientow i zlecen',
            'pt': 'Clientes e pedidos ilimitados',
            'tr': 'Sinirsiz musteri ve siparis',
            'zh': '客户与订单无限制',
            'es': 'Clientes y pedidos ilimitados',
            'it': 'Clienti e ordini illimitati',
            'de': 'Unbegrenzte Kunden und Auftrage',
          }),
          _pick(context, {
            'en': 'Full reminder automation',
            'ru': 'Полная автоматизация напоминаний',
            'pl': 'Pelna automatyzacja przypomnien',
            'pt': 'Automacao completa de lembretes',
            'tr': 'Tam hatirlatici otomasyonu',
            'zh': '完整提醒自动化',
            'es': 'Automatizacion completa de recordatorios',
            'it': 'Automazione completa dei promemoria',
            'de': 'Vollstandige Erinnerungs-Automatisierung',
          }),
          _pick(context, {
            'en': 'Unlimited chat attachments',
            'ru': 'Безлимит вложений в чате',
            'pl': 'Nielimitowane zalaczniki czatu',
            'pt': 'Anexos de chat ilimitados',
            'tr': 'Sinirsiz sohbet ekleri',
            'zh': '聊天附件无限制',
            'es': 'Adjuntos de chat ilimitados',
            'it': 'Allegati chat illimitati',
            'de': 'Unbegrenzte Chat-Anhange',
          }),
          _pick(context, {
            'en': 'Cloud media sync',
            'ru': 'Синхронизация медиа с облаком',
            'pl': 'Synchronizacja mediow w chmurze',
            'pt': 'Sincronizacao de midia em nuvem',
            'tr': 'Bulut medya esitleme',
            'zh': '云端媒体同步',
            'es': 'Sincronizacion de medios en la nube',
            'it': 'Sincronizzazione media cloud',
            'de': 'Cloud-Medien-Synchronisierung',
          }),
          _pick(context, {
            'en': 'Revenue and repeat-client analytics',
            'ru': 'Аналитика выручки и возвратных клиентов',
            'pl': 'Analityka przychodow i powracajacych klientow',
            'pt': 'Analise de receita e clientes recorrentes',
            'tr': 'Gelir ve tekrar gelen musteri analizi',
            'zh': '营收与复购客户分析',
            'es': 'Analitica de ingresos y clientes recurrentes',
            'it': 'Analisi ricavi e clienti ricorrenti',
            'de': 'Umsatz- und Stammkunden-Analysen',
          }),
          _pick(context, {
            'en': 'Export and priority support',
            'ru': 'Экспорт и приоритетная поддержка',
            'pl': 'Eksport i priorytetowe wsparcie',
            'pt': 'Exportacao e suporte prioritario',
            'tr': 'Disa aktarma ve oncelikli destek',
            'zh': '导出与优先支持',
            'es': 'Exportacion y soporte prioritario',
            'it': 'Export e supporto prioritario',
            'de': 'Export und priorisierter Support',
          }),
        ];
      case AppPlan.business:
        return [
          _pick(context, {
            'en': 'Up to 5 team members',
            'ru': 'До 5 сотрудников в команде',
            'pl': 'Do 5 czlonkow zespolu',
            'pt': 'Ate 5 membros da equipe',
            'tr': '5 ekip uyesine kadar',
            'zh': '最多 5 名团队成员',
            'es': 'Hasta 5 miembros del equipo',
            'it': 'Fino a 5 membri del team',
            'de': 'Bis zu 5 Teammitglieder',
          }),
          _pick(context, {
            'en': 'Roles and permissions',
            'ru': 'Роли и права доступа',
            'pl': 'Role i uprawnienia',
            'pt': 'Funcoes e permissoes',
            'tr': 'Roller ve izinler',
            'zh': '角色与权限',
            'es': 'Roles y permisos',
            'it': 'Ruoli e permessi',
            'de': 'Rollen und Berechtigungen',
          }),
          _pick(context, {
            'en': 'Shared team calendar',
            'ru': 'Общий календарь команды',
            'pl': 'Wspolny kalendarz zespolu',
            'pt': 'Calendario compartilhado da equipe',
            'tr': 'Paylasilan ekip takvimi',
            'zh': '团队共享日历',
            'es': 'Calendario compartido del equipo',
            'it': 'Calendario condiviso del team',
            'de': 'Gemeinsamer Team-Kalender',
          }),
          _pick(context, {
            'en': 'Organization-wide data sync',
            'ru': 'Синхронизация данных по всей организации',
            'pl': 'Synchronizacja danych w calej organizacji',
            'pt': 'Sincronizacao de dados em toda a organizacao',
            'tr': 'Kurulus genelinde veri esitleme',
            'zh': '全组织数据同步',
            'es': 'Sincronizacion de datos en toda la organizacion',
            'it': 'Sincronizzazione dati a livello organizzazione',
            'de': 'Daten-Synchronisierung in der gesamten Organisation',
          }),
          _pick(context, {
            'en': 'Performance view by staff member',
            'ru': 'Оценка эффективности по каждому сотруднику',
            'pl': 'Widok wydajnosci wedlug pracownika',
            'pt': 'Visao de desempenho por membro da equipe',
            'tr': 'Personel bazinda performans gorunumu',
            'zh': '按员工查看绩效',
            'es': 'Vista de rendimiento por empleado',
            'it': 'Vista performance per membro del team',
            'de': 'Leistungsansicht pro Mitarbeiter',
          }),
          _pick(context, {
            'en': 'Team chat and invite flow',
            'ru': 'Командный чат и система приглашений',
            'pl': 'Czat zespolowy i system zaproszen',
            'pt': 'Chat da equipe e fluxo de convites',
            'tr': 'Ekip sohbeti ve davet akisi',
            'zh': '团队聊天与邀请流程',
            'es': 'Chat de equipo y flujo de invitaciones',
            'it': 'Chat team e flusso inviti',
            'de': 'Team-Chat und Einladungsablauf',
          }),
        ];
    }
  }

  static String nextStepTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Next implementation step',
      'ru': 'Следующий шаг внедрения',
      'pl': 'Nastepny krok wdrozenia',
      'pt': 'Proximo passo de implementacao',
      'tr': 'Sonraki uygulama adimi',
      'zh': '下一步实施',
      'es': 'Siguiente paso de implementacion',
      'it': 'Prossimo passo di implementazione',
      'de': 'Nachster Implementierungsschritt',
    });
  }

  static String nextStepBody(BuildContext context) {
    return _pick(context, {
      'en':
          'Connect Google Play Billing or RevenueCat and map app access to three plan states: free, pro and business.',
      'ru':
          'Подключите Google Play Billing или RevenueCat и свяжите доступ в приложении с тремя состояниями тарифа: free, pro и business.',
      'pl':
          'Podlacz Google Play Billing lub RevenueCat i powiaz dostep aplikacji z trzema stanami planu: free, pro i business.',
      'pt':
          'Conecte Google Play Billing ou RevenueCat e vincule o acesso do app aos tres estados do plano: free, pro e business.',
      'tr':
          'Google Play Billing veya RevenueCat baglayin ve uygulama erisimini uc plan durumuna esleyin: free, pro ve business.',
      'zh':
          '接入 Google Play Billing 或 RevenueCat，并将应用权限映射到 free、pro、business 三种套餐状态。',
      'es':
          'Conecta Google Play Billing o RevenueCat y vincula el acceso de la app a tres estados de plan: free, pro y business.',
      'it':
          'Collega Google Play Billing o RevenueCat e mappa gli accessi app sui tre stati piano: free, pro e business.',
      'de':
          'Verbinde Google Play Billing oder RevenueCat und ordne App-Zugriffe den drei Tarifzustanden zu: free, pro und business.',
    });
  }

  static String debugTitle(BuildContext context) {
    return _pick(context, {
      'en': 'Debug billing scaffold',
      'ru': 'Отладочный блок биллинга',
      'pl': 'Debugowy blok billingowy',
      'pt': 'Bloco de debug de billing',
      'tr': 'Hata ayiklama faturalama blogu',
      'zh': '计费调试模块',
      'es': 'Bloque de depuracion de facturacion',
      'it': 'Blocco debug billing',
      'de': 'Debug-Billing-Block',
    });
  }

  static String debugBody(BuildContext context) {
    return _pick(context, {
      'en':
          'Visible only in debug builds. Useful before RevenueCat or Google Play Billing is connected.',
      'ru':
          'Виден только в debug-сборках. Полезен до подключения RevenueCat или Google Play Billing.',
      'pl':
          'Widoczne tylko w buildach debug. Przydatne przed podlaczeniem RevenueCat lub Google Play Billing.',
      'pt':
          'Visivel apenas em builds de debug. Util antes de conectar RevenueCat ou Google Play Billing.',
      'tr':
          'Yalnizca debug derlemelerde gorunur. RevenueCat veya Google Play Billing baglanmadan once kullanislidir.',
      'zh': '仅在调试构建中可见。在接入 RevenueCat 或 Google Play Billing 前很有用。',
      'es':
          'Visible solo en builds de depuracion. Util antes de conectar RevenueCat o Google Play Billing.',
      'it':
          'Visibile solo nelle build debug. Utile prima di collegare RevenueCat o Google Play Billing.',
      'de':
          'Nur in Debug-Builds sichtbar. Nützlich vor der Anbindung von RevenueCat oder Google Play Billing.',
    });
  }

  static String debugPlanSwitched(BuildContext context, AppPlan plan) {
    final prefix = _pick(context, {
      'en': 'Debug plan switched to',
      'ru': 'Debug-тариф переключен на',
      'pl': 'Plan debug przelaczono na',
      'pt': 'Plano de debug alterado para',
      'tr': 'Hata ayiklama plani su sekilde degistirildi',
      'zh': '调试套餐已切换为',
      'es': 'Plan de depuracion cambiado a',
      'it': 'Piano debug cambiato in',
      'de': 'Debug-Tarif umgestellt auf',
    });
    return '$prefix ${planName(context, plan)}';
  }

  static String debugSetPlan(BuildContext context, AppPlan plan) {
    final prefix = _pick(context, {
      'en': 'Set',
      'ru': 'Установить',
      'pl': 'Ustaw',
      'pt': 'Definir',
      'tr': 'Ayarla',
      'zh': '设为',
      'es': 'Establecer',
      'it': 'Imposta',
      'de': 'Setze',
    });
    return '$prefix ${planName(context, plan)}';
  }
}
