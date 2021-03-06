if GetLocale() ~= 'ruRU' then return end
local _, Addon = ...
local L = Addon.Locals

L.AddWaypoint = 'Добавить точку'
L.BattlePets = 'Боевые питомцы'
L.CapturedPets = 'Захваченные питомцы'
L.CommonSearches = 'Частые запросы'
L.FilterPets = 'Фильтр питомцев'
L.ShowJournal = 'Показать в журнале'
L.Maximized = 'увеличения'
L.ShowStables = 'Показать смотрителей'
L.ShowPets = 'Показать боевых питомцев'
L.StableTip = '|cffffd200Приезжайте сюда, чтобы исцелить ваших питомцев за небольшую плату.|r'
L.UpgradeAlert = 'Дикие обновления появились!'
L.ZoneTracker = 'Мониторинг зоны'

L.Tutorial = {
[[Добро пожаловать! Теперь вы используете |cffffd200PetTracker|r, |cffffd200Jaliborc'а|r.

Это краткое руководство поможет Вам быстро приступить к работе с аддоном, так чтобы Вы делали то, что действительно важно: чтобы поймать... кхм... захватить их всех!]],

[[PetTracker поможет Вам контролировать свой прогресс зоны, в которой Вы находитесь.

|cffffd200Мониторинг зоны|r показывает, какие животные у Вас отсутствуют, и редкость тех, что Вы поймали.]],

[[Чтобы скрыть мониторинг зоны, |cffffd200щелкните правой кнопкой|r мыши по заголовку списка целей. Затем отключите |cffffd200показ боевых питомцев|r.

Вы также можете отключить показ |cffffd200захваченных питомцев|r, чтобы отображать только питомцев которых у Вас нет.]],

'Сейчас мы увидим, что PetTracker может делать с Вашей картой мира. Пожалуйста, |cffffd200откройте|r ее, чтобы начать работу.',

[[PetTracker показывает возможные источники всех питомцев на карте мира от места поимки до продавцов.

Чтобы скрыть эти места, откройте выпадающее меню в |cffffd200опциях карты|r и отключите |cffffd200показ боевых питомцев|r.]],

[[Вы можете также фильтровать питомцев которых хотите отображать на карте в выделенной строке поиска. Вот несколько примеров:

• |cffffd200Кошка|r для кошек.
• |cffffd200Отсутствует|r для видов которыми Вы не владеете.
• |cffffd200Водный|r для водных видов.
• |cffffd200Задание|r для видов достуных через квесты.
• |cffffd200Лес|r для видов, которые населяют леса.]],

[[Далее вы можете использовать поиск для получения более точных результатов:

• |cffffd200Водная кошка|r для... водных кошек!
• |cffffd200Нет кошки|r для всех что не кошки.
• |cffffd200> Обычный|r для видов, которые у Вас есть необычные животные или лучше.
• |cffffd200Лес или водный|r для видов, которые населяют леса или водные.|r]],

[[Вот и все! В будущих версиях, помните, Вы сможете всегда посмотреть эти учебники в меню |cffffd200Интерфейс|r, на вкладке |cffffd200Модификации|r.]]
}