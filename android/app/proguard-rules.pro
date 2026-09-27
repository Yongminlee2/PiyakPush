# 광고 SDK → WorkManager → Room. Room이 WorkDatabase_Impl 기본 생성자를
# 리플렉션으로 부르는데 R8이 지워서, 릴리스만 켜자마자 죽었다
# (androidx.startup.InitializationProvider → WorkDatabase 생성 실패).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
