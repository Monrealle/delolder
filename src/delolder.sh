#!/bin/bash
# delolder — удаление файлов старше N дней из указанных каталогов
# Использование: delolder [-v|-d] N [--] каталоги...

set -o nounset
verbose=0
dry_run=0
days=""
dirs=()
end_opts=0

# Разбор аргументов
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
        end_opts=1
        shift
        continue
    fi

    if [[ $end_opts -eq 1 ]]; then
        # Всё после -- считается каталогом, даже если начинается с '-'
        dirs+=("$1")
        shift
        continue
    fi

    case "$1" in
        -v)
            verbose=1
            shift
            ;;
        -d)
            dry_run=1
            shift
            ;;
        -*)
            # Любая другая опция, начинающаяся с '-', — ошибка
            echo "Ошибка: неизвестная опция $1" >&2
            exit 1
            ;;
        *)
            # Первый неопциональный аргумент — количество дней
            if [[ -z "$days" ]]; then
                days="$1"
            else
                dirs+=("$1")
            fi
            shift
            ;;
    esac
done

# Проверки
if [[ -z "$days" ]]; then
    echo "Ошибка: не указано количество дней" >&2
    exit 1
fi
if ! [[ "$days" =~ ^[1-9][0-9]*$ ]]; then
    echo "Ошибка: количество дней должно быть положительным целым числом" >&2
    exit 1
fi
if [[ ${#dirs[@]} -eq 0 ]]; then
    echo "Ошибка: не указаны каталоги для очистки" >&2
    exit 1
fi

# Удаление дубликатов каталогов (с сохранением порядка первого появления)
declare -A seen
uniq_dirs=()
for d in "${dirs[@]}"; do
    if [[ -z "${seen[$d]:-}" ]]; then
        uniq_dirs+=("$d")
        seen[$d]=1
    fi
done
dirs=("${uniq_dirs[@]}")

# ASCII-лого и информация о запуске (вывод в stderr, чтобы не попасть в stdout при -d/-v)
cat >&2 <<EOF
       __     __      __    __         
  ____╱ ╱__  ╱ ╱___  ╱ ╱___╱ ╱__  _____
 ╱ __  ╱ _ ╲╱ ╱ __ ╲╱ ╱ __  ╱ _ ╲╱ ___╱
╱ ╱_╱ ╱  __╱ ╱ ╱_╱ ╱ ╱ ╱_╱ ╱  __╱ ╱    
╲__,_╱╲___╱_╱╲____╱_╱╲__,_╱╲___╱_╱     
                                       
EOF
echo >&2 "delolder: запущен поиск файлов старше $days дней в каталогах: ${dirs[*]}"

# Действие
if [[ $dry_run -eq 1 ]]; then
    # dry-run: только вывод списка файлов, которые были бы удалены
    find "${dirs[@]}" -type f -mtime +"$days" -print 2>/dev/null
elif [[ $verbose -eq 1 ]]; then
    # verbose: выводим имена удаляемых файлов и удаляем их
    find "${dirs[@]}" -type f -mtime +"$days" -print -delete
else
    # обычный режим: тихое удаление
    find "${dirs[@]}" -type f -mtime +"$days" -delete
fi
