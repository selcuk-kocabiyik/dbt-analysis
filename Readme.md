# Daily Metrics DBT Projesi

Kullanıcı seviyesindeki günlük oyun metriklerinden toplanmış günlük metrikleri oluşturan bir DBT projesi.

## Proje Genel Bakış

Bu proje, ham kullanıcı seviyesindeki günlük oyun metriklerini, oyun oynama, para kazanma ve performans sinyallerini gün, ülke ve platform bazında özetleyen toplanmış bir modele dönüştürür.

![Output Model Verisi](images/example.png)


### Gereksinimler
- DBT Core kurulu
- Google Cloud SDK yapılandırılmış
- BigQuery dataset erişimi: `fiery-tribute-466414-s2.bi_projects`

### Yükleme
```bash
pip install dbt-bigquery
dbt deps
```

### Yapılandırma
`profiles.yml` dosyanızı BigQuery bilgilerinizle güncelleyin:
```yaml
daily_metrics:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: fiery-tribute-466414-s2
      dataset: bi_projects
      location: US
      keyfile: path/to/service-account.json
```

## Veri Kaynakları

### Ham Veri Şeması
- **Tablo**: `raw_user_daily_metrics`
- **Sütunlar**:
  - user_id: Benzersiz kullanıcı tanımlayıcısı
  - event_date: Aktivite tarihi
  - install_date: Kullanıcı kurulum tarihi
  - platform: ANDROID/IOS
  - country: Kullanıcı ülkesi
  - total_session_count: Günlük oturum sayısı
  - total_session_duration: Günlük oturum süresi
  - match_start_count: Başlatılan maç sayısı
  - match_end_count: Tamamlanan maç sayısı
  - victory_count: Kazanılan maç sayısı
  - defeat_count: Kaybedilen maç sayısı
  - server_connection_error: Sunucu hata sayısı
  - iap_revenue: Uygulama içi satın alma geliri
  - ad_revenue: Reklam geliri

## Modeller

### daily_metrics
event_date, country ve platform bazında toplanmış metrikler:

- **event_date**: Aktivite tarihi
- **country**: Kullanıcının ülkesi
- **platform**: Kullanıcının platformu
- **dau**: Günlük Aktif Kullanıcılar
- **total_iap_revenue**: Toplam IAP geliri
- **total_ad_revenue**: Toplam reklam geliri
- **arpdau**: DAU başına ortalama gelir
- **matches_started**: Başlatılan toplam maç
- **match_per_dau**: DAU başına ortalama maç
- **win_ratio**: Kazanma oranı
- **defeat_ratio**: Kaybetme oranı
- **server_error_per_dau**: DAU başına sunucu hatası

## Kullanım

```bash
# Modelleri çalıştır
dbt run

# Modelleri test et
dbt test

# Döküman oluştur
dbt docs generate
dbt docs serve
```

## Proje Yapısı

```
.
├── dbt_project.yml
├── models/
│   ├── schema.yml
│   └── daily_metrics.sql
├── profiles.yml.example
└── README.md
```

## Temel Bulgular ve Varsayımlar

### Veri Kalite Kontrolleri
- user_id benzersizliğini gün bazında doğrulandı
- Kritik alanlardaki null değerler kontrol edildi
- Gelir alanlarının negatif olmadığı doğrulandı

### Varsayımlar
- Match end count tamamlanan maçları temsil eder
- Sunucu hataları kullanıcı başına gün bazında kümülatiftir
- Gelir alanları aynı para birimindedir

### İş Metrikleri
- ARPDAU hem IAP hem de reklam gelirini birleştirir
- Kazanma/kaybetme oranları sadece tamamlanan maçlar için hesaplanır
- Sunucu hata oranı platform kararlılığını gösterir

## Performans Optimizasyonları

### Uygulanmış
- Verimli sorgulama için event_date'e göre bölümleme
- country ve platform'a göre kümeleme
- Büyük veri setleri için incremental model

## Dashboard

Looker Studio'da oluşturulan interaktif dashboard:
- Günlük kullanıcı trendleri
- Ülke/platform bazında gelir metrikleri
- Maç tamamlama ve kazanma oranları
- Platform performans göstergeleri

**Dashboard Linki**: [Oluşturulduktan sonra eklenecek]