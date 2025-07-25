import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqList = [
      {
        "question": "Uygulama nedir ve ne işe yarar?",
        "answer":
        "Bu uygulama, yazılım öğrenmek isteyen bireyler için tasarlanmış bir eğitim platformudur. Günlük görevlerle, hedef dillerle ve zorluk seviyeleriyle öğrenme sürecinizi daha verimli hale getirir."
      },
      {
        "question": "Günlük görev sistemi nasıl çalışır?",
        "answer":
        "Günlük görev sistemi, her gün belirlediğiniz süre kadar (örneğin 5, 10, 15 dk) çalışmanızı hatırlatır ve bu süreyi tamamladığınızda ilerlemenizi takip eder."
      },
      {
        "question": "Hedef dil nedir ve nasıl seçilir?",
        "answer":
        "Hedef dil, öğrenmek istediğiniz programlama dilini temsil eder. Profili düzenle kısmından Python, C#, Java ve daha fazlasını seçebilirsiniz."
      },
      {
        "question": "Zorluk seviyesi neyi etkiler?",
        "answer":
        "Zorluk seviyesi, içeriklerin ve görevlerin karmaşıklığını belirler. Kolay, Orta veya Zor seçeneklerinden birini seçerek kendinize en uygun seviyeyi ayarlayabilirsiniz."
      },
      {
        "question": "Avatarımı nasıl değiştirebilirim?",
        "answer":
        "Profili Düzenle ekranından 'Avatarı Değiştir' butonuna tıklayarak farklı temalardaki avatarları seçebilirsiniz."
      },
      {
        "question": "Şifremi unuttum, nasıl sıfırlarım?",
        "answer":
        "Şifreyi Değiştir kısmına giderek e-posta adresinizi girin. Size bir sıfırlama bağlantısı gönderilecektir. Gelen kutunuzu kontrol edin."
      },
      {
        "question": "E-posta adresimi nasıl güncellerim?",
        "answer":
        "Ayarlar kısmından 'E-Posta Değiştir' seçeneğine tıklayıp yeni adresinizi girin. Doğrulama bağlantısı e-posta adresinize gönderilecektir."
      },
      {
        "question": "Hesabımı silersem verilerim kaybolur mu?",
        "answer":
        "Evet. Hesabınızı silerseniz tüm ilerlemeniz, görev geçmişiniz ve kişisel ayarlarınız kalıcı olarak silinir. Bu işlem geri alınamaz."
      },
      {
        "question": "Karanlık mod desteği var mı?",
        "answer":
        "Evet, uygulama varsayılan olarak karanlık bir temaya sahiptir. Daha rahat bir kullanım deneyimi için optimize edilmiştir."
      },
      {
        "question": "Bildirimleri nasıl açıp kapatabilirim?",
        "answer":
        "Profili Düzenle kısmında 'Bildirimler' bölümünden bildirimleri açabilir veya kapatabilirsiniz."
      },
      {
        "question": "Yeni bir programlama dili ekleniyor mu?",
        "answer":
        "Uygulama sürekli geliştirilmektedir. Yakında Kotlin, JavaScript gibi yeni diller de eklenecektir. Bildirimleri açık tutarak haberdar olabilirsiniz."
      },
      {
        "question": "Tekrar eden görevleri nasıl yönetebilirim?",
        "answer":
        "Görev yönetimi sistemi ile günlük olarak tamamladığınız görevler sıfırlanır. Geri bildirimlerde gelişmiş takip sistemi talep edebilirsiniz."
      },
      {
        "question": "Verilerim güvende mi?",
        "answer":
        "Evet. Uygulama, kullanıcı verilerini şifreli bir şekilde saklar ve üçüncü taraflarla paylaşmaz. Gizlilik politikamızı detaylıca inceleyebilirsiniz."
      },
      {
        "question": "Destek almak istiyorum, ne yapmalıyım?",
        "answer":
        "Ayarlar bölümünden 'Öneri ve İstek' sekmesini kullanarak bizimle iletişime geçebilirsiniz. Tüm sorularınızı memnuniyetle yanıtlarız."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/arkaplan.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ListView.separated(
              itemCount: faqList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faqList[index]["question"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        faqList[index]["answer"]!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
