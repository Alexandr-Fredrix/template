# Конфигурационные файлы для линтеров и тестов

Этот каталог содержит примеры конфигурационных файлов, которые используются в GitLab CI pipelines.

## 📋 Содержание

### ESLint - `.eslintrc.json`
Линтер для JavaScript/TypeScript кода.

**Установка:**
```bash
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks eslint-config-prettier
```

**Использование:**
```bash
npx eslint . --ext .js,.jsx,.ts,.tsx
npx eslint . --fix  # Автоисправление
```

### Prettier - `.prettierrc`
Форматирование кода.

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false
}
```

**Установка:**
```bash
npm install --save-dev prettier
```

**Использование:**
```bash
npx prettier --write "**/*.{js,jsx,ts,tsx,json,css,md}"
```

### YAMLLint - `.yamllint.yml`
Проверка YAML файлов.

**Установка:**
```bash
pip install yamllint
# или
docker pull cytopia/yamllint
```

**Использование:**
```bash
yamllint -c .yamllint.yml .
```

### Jest - `jest.config.js`
Тестирование JavaScript/TypeScript.

**Установка:**
```bash
npm install --save-dev jest @types/jest ts-jest jest-junit
```

**Использование:**
```bash
npm test
npm test -- --coverage
npm test -- --watch
```

### Pytest - `pytest.ini`
Тестирование Python.

**Установка:**
```bash
pip install pytest pytest-cov pytest-xdist
```

**Использование:**
```bash
pytest
pytest --cov=src
pytest -n auto  # Параллельное выполнение
pytest -k test_specific  # Конкретный тест
pytest -m unit  # По маркеру
```

## 🔧 Дополнительные конфигурации

### TypeScript - `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Python - `.flake8`
```ini
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude =
    .git,
    __pycache__,
    .venv,
    venv,
    build,
    dist
per-file-ignores =
    __init__.py:F401
```

### Python - `pyproject.toml` (Black)
```toml
[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'
extend-exclude = '''
/(
  | .git
  | .venv
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
line_length = 88
```

### Go - `.golangci.yml`
```yaml
run:
  timeout: 5m
  tests: true

linters:
  enable:
    - gofmt
    - golint
    - govet
    - errcheck
    - staticcheck
    - unused
    - gosimple
    - structcheck
    - varcheck
    - ineffassign
    - deadcode

linters-settings:
  golint:
    min-confidence: 0.8
  gofmt:
    simplify: true
```

## 🚀 Интеграция с GitLab CI

Скопируйте нужные конфигурационные файлы в корень вашего проекта:

```bash
cp gitlab-ci/config-examples/.eslintrc.json .
cp gitlab-ci/config-examples/.yamllint.yml .
cp gitlab-ci/config-examples/jest.config.js .
cp gitlab-ci/config-examples/pytest.ini .
```

Затем используйте один из pipeline примеров:

```bash
cp gitlab-ci/pipelines/docker-executor-advanced.yml .gitlab-ci.yml
```

## 📊 Отчеты в GitLab

Все конфигурации настроены для генерации отчетов, совместимых с GitLab:

- **JUnit XML** - для тестов
- **Cobertura XML** - для coverage
- **Code Quality JSON** - для линтеров

Эти отчеты автоматически отображаются в Merge Requests:
- ✅ Test results
- 📊 Code coverage
- 🔍 Code quality issues

## 💡 Best Practices

### 1. Pre-commit hooks
Используйте pre-commit для запуска линтеров локально:

```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json

  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.50.0
    hooks:
      - id: eslint
        files: \.(js|jsx|ts|tsx)$
```

### 2. Editor integration
Настройте ваш редактор для использования этих конфигураций:

**VS Code** - `.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "eslint.validate": ["javascript", "typescript", "javascriptreact", "typescriptreact"],
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
```

### 3. CI/CD оптимизация
- Кешируйте `node_modules/` и `.venv/`
- Используйте `allow_failure: true` для не критичных линтеров
- Запускайте полные тесты только на main ветке
- Используйте `rules` для условного запуска

## 📚 Дополнительные ресурсы

- [ESLint Documentation](https://eslint.org/docs/latest/)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Pytest Documentation](https://docs.pytest.org/)
- [YAMLLint Documentation](https://yamllint.readthedocs.io/)
