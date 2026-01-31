# MongoDB для DevOps

MongoDB - популярная NoSQL документо-ориентированная база данных.

## 🚀 Быстрый старт

### Запуск в Docker

```bash
cd docker/
docker-compose up -d
```

### Подключение

```bash
# Подключение к MongoDB
mongosh mongodb://localhost:27017

# С аутентификацией
mongosh "mongodb://username:password@localhost:27017/myapp"

# MongoDB Compass (GUI)
# mongodb://localhost:27017
```

## 💡 Основные команды

### Управление базами данных

```javascript
// Показать базы данных
show dbs

// Использовать/создать базу
use myapp

// Показать текущую базу
db

// Удалить базу
db.dropDatabase()

// Показать коллекции
show collections

// Статистика базы
db.stats()
```

### Управление коллекциями

```javascript
// Создать коллекцию
db.createCollection("users")

// С опциями
db.createCollection("users", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["name", "email"],
            properties: {
                name: { bsonType: "string" },
                email: { bsonType: "string" },
                age: { bsonType: "int", minimum: 0 }
            }
        }
    }
})

// Удалить коллекцию
db.users.drop()

// Переименовать коллекцию
db.users.renameCollection("app_users")
```

### Управление пользователями

```javascript
// Создать администратора
use admin
db.createUser({
    user: "admin",
    pwd: "password",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
})

// Создать пользователя для базы данных
use myapp
db.createUser({
    user: "myapp_user",
    pwd: "password",
    roles: [
        { role: "readWrite", db: "myapp" }
    ]
})

// Read-only пользователь
db.createUser({
    user: "readonly",
    pwd: "password",
    roles: [ { role: "read", db: "myapp" } ]
})

// Показать пользователей
db.getUsers()

// Удалить пользователя
db.dropUser("myapp_user")

// Изменить пароль
db.changeUserPassword("myapp_user", "new_password")
```

## 📝 CRUD операции

### Create

```javascript
// Вставить один документ
db.users.insertOne({
    name: "John Doe",
    email: "john@example.com",
    age: 30,
    created_at: new Date()
})

// Вставить несколько документов
db.users.insertMany([
    { name: "Alice", email: "alice@example.com" },
    { name: "Bob", email: "bob@example.com" },
    { name: "Charlie", email: "charlie@example.com" }
])
```

### Read

```javascript
// Найти все документы
db.users.find()

// Найти один документ
db.users.findOne({ name: "John Doe" })

// С условием
db.users.find({ age: { $gt: 25 } })

// Несколько условий
db.users.find({
    age: { $gte: 18, $lte: 65 },
    email: { $regex: /@gmail.com$/ }
})

// Проекция (выбрать конкретные поля)
db.users.find({}, { name: 1, email: 1, _id: 0 })

// Сортировка
db.users.find().sort({ age: -1 })  // -1 = DESC, 1 = ASC

// Лимит и skip
db.users.find().limit(10).skip(20)

// Подсчёт
db.users.countDocuments({ age: { $gt: 25 } })
```

### Update

```javascript
// Обновить один документ
db.users.updateOne(
    { name: "John Doe" },
    { $set: { email: "newemail@example.com" } }
)

// Обновить несколько документов
db.users.updateMany(
    { age: { $lt: 18 } },
    { $set: { status: "minor" } }
)

// Upsert (вставить если не существует)
db.users.updateOne(
    { email: "test@example.com" },
    { $set: { name: "Test User" } },
    { upsert: true }
)

// Инкремент
db.users.updateOne(
    { name: "John Doe" },
    { $inc: { age: 1 } }
)

// Добавить в массив
db.users.updateOne(
    { name: "John Doe" },
    { $push: { tags: "premium" } }
)

// Удалить поле
db.users.updateOne(
    { name: "John Doe" },
    { $unset: { temporaryField: "" } }
)
```

### Delete

```javascript
// Удалить один документ
db.users.deleteOne({ name: "John Doe" })

// Удалить несколько документов
db.users.deleteMany({ age: { $lt: 18 } })

// Удалить все документы
db.users.deleteMany({})
```

## 🔧 DevOps задачи

### Backup

```bash
# Backup базы данных
mongodump --db myapp --out /backups/

# С аутентификацией
mongodump --uri="mongodb://username:password@localhost:27017/myapp" --out /backups/

# Backup в архив
mongodump --db myapp --archive=/backups/myapp.archive

# С сжатием
mongodump --db myapp --archive=/backups/myapp.archive --gzip

# Backup конкретной коллекции
mongodump --db myapp --collection users --out /backups/

# Использовать готовый скрипт
./scripts/backup-mongodb.sh
```

### Restore

```bash
# Restore базы данных
mongorestore --db myapp /backups/myapp/

# С аутентификацией
mongorestore --uri="mongodb://username:password@localhost:27017/myapp" /backups/myapp/

# Restore из архива
mongorestore --archive=/backups/myapp.archive

# С распаковкой
mongorestore --archive=/backups/myapp.archive --gzip

# Restore конкретной коллекции
mongorestore --db myapp --collection users /backups/myapp/users.bson

# Использовать готовый скрипт
./scripts/restore-mongodb.sh
```

### Мониторинг

```javascript
// Статус сервера
db.serverStatus()

// Текущие операции
db.currentOp()

// Убить операцию
db.killOp(12345)

// Статистика базы данных
db.stats()

// Статистика коллекции
db.users.stats()

// Профилирование
db.setProfilingLevel(2)  // 0=off, 1=slow, 2=all
db.system.profile.find().limit(10).sort({ ts: -1 })

// Размер коллекций
db.users.totalSize()
db.users.storageSize()
db.users.totalIndexSize()
```

## 🔍 Индексы

```javascript
// Создать индекс
db.users.createIndex({ email: 1 })

// Составной индекс
db.users.createIndex({ name: 1, age: -1 })

// Уникальный индекс
db.users.createIndex({ email: 1 }, { unique: true })

// Частичный индекс
db.users.createIndex(
    { email: 1 },
    { partialFilterExpression: { age: { $gte: 18 } } }
)

// TTL индекс (автоудаление)
db.sessions.createIndex(
    { createdAt: 1 },
    { expireAfterSeconds: 3600 }
)

// Text индекс для поиска
db.articles.createIndex({ content: "text" })

// Geospatial индекс
db.places.createIndex({ location: "2dsphere" })

// Показать индексы
db.users.getIndexes()

// Удалить индекс
db.users.dropIndex("email_1")

// Анализ запроса
db.users.find({ email: "test@example.com" }).explain("executionStats")
```

## 📊 Aggregation

```javascript
// Группировка
db.users.aggregate([
    { $group: {
        _id: "$country",
        count: { $sum: 1 },
        avgAge: { $avg: "$age" }
    }}
])

// Pipeline
db.orders.aggregate([
    { $match: { status: "completed" } },
    { $group: {
        _id: "$customerId",
        total: { $sum: "$amount" }
    }},
    { $sort: { total: -1 } },
    { $limit: 10 }
])

// Lookup (JOIN)
db.orders.aggregate([
    { $lookup: {
        from: "customers",
        localField: "customerId",
        foreignField: "_id",
        as: "customer"
    }}
])
```

## 🔄 Репликация (Replica Set)

```javascript
// Инициализация replica set
rs.initiate({
    _id: "rs0",
    members: [
        { _id: 0, host: "mongo1:27017" },
        { _id: 1, host: "mongo2:27017" },
        { _id: 2, host: "mongo3:27017" }
    ]
})

// Статус
rs.status()

// Добавить member
rs.add("mongo4:27017")

// Удалить member
rs.remove("mongo4:27017")

// Конфигурация
rs.conf()
```

## 🔒 Безопасность

```javascript
// Включить аутентификацию (в mongod.conf)
security:
    authorization: enabled

// Создать root пользователя
use admin
db.createUser({
    user: "root",
    pwd: "password",
    roles: [ "root" ]
})

// Роли
db.grantRolesToUser("myuser", [
    { role: "readWrite", db: "myapp" },
    { role: "read", db: "analytics" }
])

// SSL/TLS подключение
mongosh "mongodb://username:password@localhost:27017/myapp?tls=true&tlsCAFile=/path/to/ca.pem"
```

## 🎯 Чек-лист для Production

- [ ] Настроен регулярный backup
- [ ] Настроена replica set (минимум 3 узла)
- [ ] Настроен мониторинг
- [ ] Включена аутентификация
- [ ] Созданы пользователи с минимальными правами
- [ ] Настроены индексы
- [ ] Настроен профилировщик
- [ ] Ограничен доступ по сети
- [ ] Настроен SSL/TLS
- [ ] Документированы процедуры восстановления

## 📚 Дополнительно

- [MongoDB Documentation](https://docs.mongodb.com/)
- [Скрипты автоматизации](scripts/)
