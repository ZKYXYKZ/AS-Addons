const fs = require("fs");
const path = require("path");

const locDir = process.argv[2];
const root = path.join(__dirname, "..");
const out = path.join(root, "community", "public", "i18n.json");
const data = JSON.parse(fs.readFileSync(path.join(root, "AS-Companion/web/data.json"), "utf8"));
const gamedb = JSON.parse(fs.readFileSync(path.join(root, "AS-Companion/web/gamedb.json"), "utf8"));
const LANGS = ["en", "pl", "cs", "de", "pt", "es", "fr", "ro", "tr", "ru", "uk", "zh", "ja", "ko"];
const NAMES = { en: "English", pl: "Polski", cs: "Čeština", de: "Deutsch", pt: "Português", es: "Español", fr: "Français", ro: "Română", tr: "Türkçe", ru: "Русский", uk: "Українська", zh: "中文", ja: "日本語", ko: "한국어" };

const UI = {
  title: ["Statistics", "Statystyki", "Statistiky", "Statistiken", "Estatísticas", "Estadísticas", "Statistiques", "Statistici", "İstatistikler", "Статистика", "Статистика", "统计", "統計", "통계"],
  sub: ["Runs shared anonymously by AS Companion players. Updated every minute.", "Rozgrywki udostępniane anonimowo przez graczy AS Companion. Aktualizacja co minutę.", "Hry anonymně sdílené hráči AS Companion. Aktualizace každou minutu.", "Anonym geteilte Runs von AS-Companion-Spielern. Jede Minute aktualisiert.", "Partidas compartilhadas anonimamente pelos jogadores do AS Companion. Atualizado a cada minuto.", "Partidas compartidas de forma anónima por los jugadores de AS Companion. Se actualiza cada minuto.", "Parties partagées anonymement par les joueurs d'AS Companion. Mise à jour chaque minute.", "Partide partajate anonim de jucătorii AS Companion. Actualizare în fiecare minut.", "AS Companion oyuncularının anonim olarak paylaştığı oyunlar. Her dakika güncellenir.", "Забеги, анонимно отправленные игроками AS Companion. Обновление каждую минуту.", "Забіги, анонімно надіслані гравцями AS Companion. Оновлення щохвилини.", "AS Companion 玩家匿名分享的对局，每分钟更新。", "AS Companion のプレイヤーが匿名で共有したラン。1 分ごとに更新。", "AS Companion 플레이어가 익명으로 공유한 판입니다. 1분마다 갱신됩니다."],
  runs: ["Runs", "Rozgrywki", "Hry", "Runs", "Partidas", "Partidas", "Parties", "Partide", "Oyunlar", "Забеги", "Забіги", "对局", "ラン", "판"],
  players: ["Players", "Gracze", "Hráči", "Spieler", "Jogadores", "Jugadores", "Joueurs", "Jucători", "Oyuncular", "Игроки", "Гравці", "玩家", "プレイヤー", "플레이어"],
  wins: ["Victories", "Zwycięstwa", "Vítězství", "Siege", "Vitórias", "Victorias", "Victoires", "Victorii", "Zaferler", "Победы", "Перемоги", "胜利", "勝利", "승리"],
  combos: ["Combinations", "Kombinacje", "Kombinace", "Kombinationen", "Combinações", "Combinaciones", "Combinaisons", "Combinații", "Kombinasyonlar", "Сочетания", "Поєднання", "组合", "組み合わせ", "조합"],
  best: ["Best runs per zone", "Najlepsze rozgrywki w strefie", "Nejlepší hry podle zóny", "Beste Runs pro Zone", "Melhores partidas por zona", "Mejores partidas por zona", "Meilleures parties par zone", "Cele mai bune partide pe zonă", "Bölgeye göre en iyi oyunlar", "Лучшие забеги по зонам", "Найкращі забіги за зонами", "各区域最佳对局", "ゾーン別ベストラン", "지역별 최고 기록"],
  groups: ["Classes, specs and races", "Klasy, specjalizacje i rasy", "Povolání, specializace a rasy", "Klassen, Spezialisierungen und Völker", "Classes, especializações e raças", "Clases, especializaciones y razas", "Classes, spés et races", "Clase, specializări și rase", "Sınıflar, uzmanlıklar ve ırklar", "Классы, специализации и расы", "Класи, спеціалізації та раси", "职业、专精与种族", "クラス・特化・種族", "직업, 전문화, 종족"],
  builds: ["Most played builds", "Najczęściej grane buildy", "Nejhranější buildy", "Meistgespielte Builds", "Builds mais jogadas", "Builds más jugadas", "Builds les plus joués", "Cele mai jucate builduri", "En çok oynanan buildler", "Самые популярные билды", "Найпопулярніші білди", "最常用的构筑", "人気のビルド", "가장 많이 쓰인 빌드"],
  spells: ["Average damage share per spell", "Średni udział obrażeń na zaklęcie", "Průměrný podíl poškození podle kouzla", "Durchschnittlicher Schadensanteil pro Zauber", "Participação média de dano por feitiço", "Porcentaje medio de daño por hechizo", "Part moyenne des dégâts par sort", "Procentul mediu de daune pe vrajă", "Büyü başına ortalama hasar payı", "Средняя доля урона по заклинаниям", "Середня частка шкоди за закляттями", "各法术平均伤害占比", "呪文別の平均ダメージ割合", "주문별 평균 피해 비중"],
  recent: ["Latest runs", "Ostatnie rozgrywki", "Poslední hry", "Neueste Runs", "Últimas partidas", "Últimas partidas", "Dernières parties", "Ultimele partide", "Son oyunlar", "Последние забеги", "Останні забіги", "最近对局", "最新のラン", "최근 판"],
  zone: ["Zone", "Strefa", "Zóna", "Zone", "Zona", "Zona", "Zone", "Zonă", "Bölge", "Зона", "Зона", "区域", "ゾーン", "지역"],
  difficulty: ["Difficulty", "Trudność", "Obtížnost", "Schwierigkeit", "Dificuldade", "Dificultad", "Difficulté", "Dificultate", "Zorluk", "Сложность", "Складність", "难度", "難易度", "난이도"],
  class: ["Class", "Klasa", "Povolání", "Klasse", "Classe", "Clase", "Classe", "Clasă", "Sınıf", "Класс", "Клас", "职业", "クラス", "직업"],
  spec: ["Spec", "Specjalizacja", "Specializace", "Spezialisierung", "Especialização", "Especialización", "Spé", "Specializare", "Uzmanlık", "Специализация", "Спеціалізація", "专精", "特化", "전문화"],
  race: ["Race", "Rasa", "Rasa", "Volk", "Raça", "Raza", "Race", "Rasă", "Irk", "Раса", "Раса", "种族", "種族", "종족"],
  level: ["Level", "Poziom", "Úroveň", "Stufe", "Nível", "Nivel", "Niveau", "Nivel", "Seviye", "Уровень", "Рівень", "等级", "レベル", "레벨"],
  duration: ["Duration", "Czas", "Délka", "Dauer", "Duração", "Duración", "Durée", "Durată", "Süre", "Длительность", "Тривалість", "时长", "時間", "시간"],
  result: ["Result", "Wynik", "Výsledek", "Ergebnis", "Resultado", "Resultado", "Résultat", "Rezultat", "Sonuç", "Итог", "Підсумок", "结果", "結果", "결과"],
  victory: ["Victory", "Zwycięstwo", "Vítězství", "Sieg", "Vitória", "Victoria", "Victoire", "Victorie", "Zafer", "Победа", "Перемога", "胜利", "勝利", "승리"],
  defeat: ["Defeat", "Porażka", "Porážka", "Niederlage", "Derrota", "Derrota", "Défaite", "Înfrângere", "Yenilgi", "Поражение", "Поразка", "失败", "敗北", "패배"],
  all: ["All", "Wszystkie", "Vše", "Alle", "Todas", "Todas", "Toutes", "Toate", "Tümü", "Все", "Усі", "全部", "すべて", "전체"],
  avgTime: ["Avg duration", "Śr. czas", "Prům. délka", "Ø Dauer", "Duração média", "Duración media", "Durée moy.", "Durată medie", "Ort. süre", "Ср. длительность", "Сер. тривалість", "平均时长", "平均時間", "평균 시간"],
  avgLevel: ["Avg level", "Śr. poziom", "Prům. úroveň", "Ø Stufe", "Nível médio", "Nivel medio", "Niveau moy.", "Nivel mediu", "Ort. seviye", "Ср. уровень", "Сер. рівень", "平均等级", "平均レベル", "평균 레벨"],
  avgDps: ["Avg DPS", "Śr. DPS", "Prům. DPS", "Ø DPS", "DPS médio", "DPS medio", "DPS moy.", "DPS mediu", "Ort. DPS", "Ср. DPS", "Сер. DPS", "平均 DPS", "平均 DPS", "평균 DPS"],
  bestDps: ["Best DPS", "Najlepszy DPS", "Nejlepší DPS", "Bester DPS", "Melhor DPS", "Mejor DPS", "Meilleur DPS", "Cel mai bun DPS", "En iyi DPS", "Лучший DPS", "Найкращий DPS", "最高 DPS", "最高 DPS", "최고 DPS"],
  build: ["Build", "Build", "Build", "Build", "Build", "Build", "Build", "Build", "Build", "Билд", "Білд", "构筑", "ビルド", "빌드"],
  copy: ["Copy for the companion", "Kopiuj do companiona", "Kopírovat pro companion", "Für den Companion kopieren", "Copiar para o companion", "Copiar para el companion", "Copier pour le compagnon", "Copiază pentru companion", "Companion için kopyala", "Копировать для компаньона", "Копіювати для компаньйона", "复制到 Companion", "Companion 用にコピー", "Companion용 복사"],
  copied: ["Copied", "Skopiowano", "Zkopírováno", "Kopiert", "Copiado", "Copiado", "Copié", "Copiat", "Kopyalandı", "Скопировано", "Скопійовано", "已复制", "コピーしました", "복사됨"],
  spell: ["Spell", "Zaklęcie", "Kouzlo", "Zauber", "Feitiço", "Hechizo", "Sort", "Vrajă", "Büyü", "Заклинание", "Закляття", "法术", "呪文", "주문"],
  share: ["Average share", "Średni udział", "Průměrný podíl", "Ø Anteil", "Participação média", "Porcentaje medio", "Part moyenne", "Procent mediu", "Ortalama pay", "Средняя доля", "Середня частка", "平均占比", "平均割合", "평균 비중"],
  date: ["Date", "Data", "Datum", "Datum", "Data", "Fecha", "Date", "Data", "Tarih", "Дата", "Дата", "日期", "日付", "날짜"],
  empty: ["No data yet.", "Brak danych.", "Zatím žádná data.", "Noch keine Daten.", "Ainda sem dados.", "Aún no hay datos.", "Pas encore de données.", "Încă nu există date.", "Henüz veri yok.", "Пока нет данных.", "Поки немає даних.", "暂无数据。", "まだデータがありません。", "아직 데이터가 없습니다."],
  normal: ["Normal", "Normalny", "Normální", "Normal", "Normal", "Normal", "Normal", "Normal", "Normal", "Обычный", "Звичайний", "普通", "ノーマル", "일반"],
  heroic: ["Heroic", "Heroiczny", "Hrdinská", "Heroisch", "Heroico", "Heroico", "Héroïque", "Eroic", "Kahramanlık", "Героический", "Героїчний", "英雄", "ヒロイック", "영웅"],
  pets: ["Pets", "Zwierzaki", "Mazlíčci", "Begleiter", "Mascotes", "Mascotas", "Familiers", "Animale", "Evcil hayvanlar", "Питомцы", "Улюбленці", "宠物", "ペット", "소환수"],
  footer: ["No player name or personal data: each companion install is only known by a random ID. Sharing can be turned off in the companion options.","Bez nazw graczy i danych osobowych: każda instalacja companiona jest znana tylko z losowego identyfikatora. Udostępnianie można wyłączyć w opcjach companiona.","Žádná jména hráčů ani osobní údaje: každá instalace companionu je známa jen podle náhodného identifikátoru. Sdílení lze vypnout v nastavení companionu.","Keine Spielernamen oder persönlichen Daten: Jede Companion-Installation ist nur über eine zufällige ID bekannt. Das Teilen lässt sich in den Companion-Optionen abschalten.","Sem nomes de jogador nem dados pessoais: cada instalação do companion é conhecida apenas por um identificador aleatório. O compartilhamento pode ser desativado nas opções do companion.","Sin nombres de jugador ni datos personales: cada instalación del companion solo se conoce por un identificador aleatorio. Se puede desactivar el envío en las opciones del companion.","Aucun pseudo ni donnée personnelle : chaque installation du compagnon n'est connue que par un identifiant aléatoire. Le partage se coupe dans les options du compagnon.","Fără nume de jucător sau date personale: fiecare instalare a companionului este cunoscută doar printr-un identificator aleatoriu. Partajarea se poate opri din opțiunile companionului.","Oyuncu adı veya kişisel veri yok: her companion kurulumu yalnızca rastgele bir kimlikle bilinir. Paylaşım companion ayarlarından kapatılabilir.","Никаких имён и личных данных: каждая установка компаньона известна только по случайному идентификатору. Отправку можно отключить в настройках компаньона.","Жодних імен і особистих даних: кожну інсталяцію компаньйона відомо лише за випадковим ідентифікатором. Надсилання можна вимкнути в налаштуваннях компаньйона.","不含玩家名或个人数据：每个 Companion 安装只以随机标识区分。可在 Companion 选项中关闭分享。","プレイヤー名や個人データは含みません。各 Companion のインストールはランダムな ID でのみ識別されます。共有は Companion の設定でオフにできます。","플레이어 이름이나 개인 정보는 없습니다. 각 Companion 설치는 무작위 ID로만 구분됩니다. 공유는 Companion 옵션에서 끌 수 있습니다."],
};

const locs = LANGS.map((_, i) => JSON.parse(fs.readFileSync(path.join(locDir, "loc-" + (i + 1) + ".json"), "utf8")));
const en = locs[0];
const out_ = { langs: LANGS.map((l) => ({ code: l, name: NAMES[l] })), t: {} };
const spellKeys = new Set(Object.keys(gamedb.abilities));
for (const c of data.classes) for (const s of c.spells) spellKeys.add(s.key);
for (const s of data.racials.concat(data.extraSpells)) spellKeys.add(s.key);
const extraNames = ["Ignite", "Pets", "Attack", "Corpse Explosion", "Hot Streak", "Pyroclasm", "Deep Wound", "Explosive Trap Effect"];

LANGS.forEach((l, i) => {
  const loc = locs[i];
  const tr = (k, fallback) => loc[k] || fallback;
  const byEn = (txt) => { const k = Object.keys(en).find((kk) => en[kk] === txt); return k && loc[k] ? loc[k] : txt; };
  const o = { ui: {}, classes: {}, trees: {}, races: {}, zones: {}, spells: {} };
  for (const [k, v] of Object.entries(UI)) o.ui[k] = v[i];
  for (const c of data.classes) {
    o.classes[c.key] = tr("class." + c.key + ".name", c.name.en);
    o.trees[c.key] = c.trees.map((t) => loc[t.name.en] || t.name.en);
  }
  for (const k of Object.keys(en).filter((x) => /^race\.[a-z]+\.name$/.test(x))) o.races[k.split(".")[1]] = loc[k];
  for (const z of Object.keys(gamedb.zones)) o.zones[z] = tr("zone." + z + ".name", gamedb.zones[z].name);
  for (const k of spellKeys) { const n = loc["ability." + k + ".name"]; if (n) o.spells[k] = n; }
  for (const n of extraNames) o.spells[n] = byEn(n);
  o.spells.Pets = UI.pets[i];
  out_.t[l] = o;
});
fs.writeFileSync(out, JSON.stringify(out_) + "\n");
const races = {}, zones = {};
for (const k of Object.keys(en).filter((x) => /^race\.[a-z]+\.name$/.test(x))) races[k.split(".")[1]] = [...new Set(locs.map((l) => l[k]).filter(Boolean))];
for (const z of Object.keys(gamedb.zones)) zones[z] = [...new Set([gamedb.zones[z].name].concat(locs.map((l) => l["zone." + z + ".name"]).filter(Boolean)))];
fs.writeFileSync(path.join(root, "community", "names.json"), JSON.stringify({ races, zones }, null, 1) + "\n");
console.log(LANGS.length + " langues -> " + path.relative(process.cwd(), out) + " (" + Math.round(fs.statSync(out).size / 1024) + " ko)");
