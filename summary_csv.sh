#!/bin/bash

POSTFIX=".mod"
CALC_MIN=true
CALC_MAX=true
CALC_AVG=true

show_help() {
    echo "Użycie: $0 [OPCJE] [PLIKI...]" 
    echo "Opcje: -p (postfix), --no-min, --no-max, --no-avg, -h (pomoc)"
    exit 0
}

# $0 - parametr pozycyjny, który przechowuje nazwę uruchomionego skryptu. Dzięki temu komunikat jest dynamiczny.

# --- PARSOWANIE ARGUMENTÓW ---
FILES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h) show_help ;;
        -p) POSTFIX="$2"; shift 2 ;;
        --no-min) CALC_MIN=false; shift ;;
        --no-max) CALC_MAX=false; shift ;;
        --no-avg) CALC_AVG=false; shift ;;
        *) FILES+=("$1"); shift ;;
    esac
done

# FILES - deklaracja pustej tablicy, bo jest nieograniczona liczba plików.
# while $# (liczba argumentów) -gt (jest większa od 0) wykonuj.
# case to switch, ;; to break.

# jeśli argument to -h to wywołaj funkcję help.
# jeśli argument to -p następny argument to POSTFIX (-p .nowy_format), więc przypisz go i przesuń o 2 (żeby pominąć oba).        1        2   
# shift przesuwa argumenty w lewo, przetworzyliśmy flagę -p i jej wartość, więc shift 2 zjada oba te argumenty i wyrzucamy je z kolejki (taśma kasy w sklepie).
# *) czyli default. Jeśli argument nie pasował do żadnej z flag to zakładamy, że jest to nazwa pliku, który mamy przetworzyć i dodajemy go do tablicy FILES
# esac kończy case
# done - po dojściu do tego miejsca bash wraca do początku whilea i sprawdza czy $# jest większe od 0, jeśli tak jedzie z case od nowa z nowym $1.

# --- FUNKCJA PRZETWARZAJĄCA (AWK) ---
process_csv() {

    local input_file=$1
    local output_file=$2

    # -F',' definiuje wejściowy separator kolumn 
    # -v wstrzykuje zmienne z basha do środowiska awk
    # OFS definiuje wyjściowy separator kolumn, żeby końcowy plik też miał przecinki
    awk -F',' -v c_min="$CALC_MIN" -v c_max="$CALC_MAX" -v c_avg="$CALC_AVG" ' 
    BEGIN { OFS="," } 

    # TO SIĘ WYKONUJE DLA KAŻDEGO WIERSZA (PĘTLA)
    {
        rows[NR] = $0   # ZAPISUJE CAŁKOWITĄ TREŚĆ AKTUALNEJ LINIJKI($0) DO TABLICY ROWS
        for (i=1; i<=NF; i++) {   # PĘTLA ITERUJĄCA PO WSZYSTKICH KOMÓRKACH W WIERSZU. NF TO LICZBA KOLUMN.
            data[NR, i] = $i    # ZAPISUJE WARTOŚCI KOMÓRKI DO TABLICY DWUWYMIAROWEJ

            if (NR > 1) {   # WARUNEK POMIJAJĄCY NAGŁÓWEK KOLUMNY
                if ($i ~ /^-?[0-9]+([.][0-9]+)?$/) {  # REGEX NA SPRAWDZENIE CZY WARTOŚĆ W POLU JEST LICZBĄ
                    val = $i + 0    # DODANIE 0 WYMUSZA TRAKTOWANIE TEKSTU JAKO LICZBĘ

                    # JEŚLI KOMÓRKA JEST LICZBĄ
                    if (!(i in count)) {    # CZY JEST TO PIERWSZA LICZBA W TEJ KOLUMNIE i
                        min[i] = max[i] = val   # JEŚLI TAK TO PRZYPISUJEMY JĄ DO min I DO max
                    } else {    # JEŚLI NIE TO ALGORYTMICZNIE PORÓRWNUJEMY I NADPISUJEMY
                        if (val < min[i]) min[i] = val
                        if (val > max[i]) max[i] = val
                    }
                    sum[i] += val   # DODAJEMY WARTOŚĆ DO SUMY KOLUMNY
                    count[i]++          # INKREMENTUJEMY LICZNIK NAPOTKANYCH LICZB
                    is_numeric[i] = 1   # FLAGA POTWIERDZAJĄCA ZNALEZIENIE LICZBY
                } else if ($i != "") {      # BLOK, DO KTÓREGO WPADAMY JEŚLI WARTOŚĆ NIE BYŁA LICZBĄ ALE NIE BYŁA TEŻ PUSTA
                    invalid[i] = 1      # USTAWIAMY FLAGĘ INVALID, ŻEBY POTEM ZIGNOROWAĆ TĄ KOLUMNĘ
                }
            }
        }
        if (NF > max_cols) max_cols = NF 
    }

    END {
        for (r=1; r<=NR; r++) print rows[r] # PRZEPISANIE STAREJ TREŚCI PLIKU DO NOWEGO PLIKU

        if(c_min == "true") {
            printf "MIN"    # PRINTF NIE DODAJE NA KONCU NOWEJ LINII
            for (i=2; i<=max_cols; i++) {
                printf "%s%s", OFS, (is_numeric[i] && !invalid[i] ? min[i] : "")
            }
            print ""
        }

        if(c_max == "true") {
            printf "MAX"
            for (i=2; i<=max_cols; i++) {
                printf "%s%s", OFS, (is_numeric[i] && !invalid[i] ? max[i] : "")
            }
            print ""
        }

        if(c_avg == "true") {
            printf "AVG"
            for (i=2; i<=max_cols; i++) {
                printf "%s%s", OFS, (is_numeric[i] && !invalid[i] ? sum[i]/count[i] : "")
            }
            print ""
        }
    }' "$input_file" > "$output_file" # > przekierowuje wyjście z awk do pliku wynikowego
}

# --- GŁÓWNA LOGIKA WYKONYWANIA ---
if [ ${#FILES[@]} -eq 0]; then
    temp_stdin=$(mktemp)
    cat > "$temp_stdin"
    process_csv "$temp_stdin" "wynik${POSTFIX}"
    cat "wynik${POSTFIX}"
    rm "$temp_stdin" "wynik${POSTFIX}"
else
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            process_csv "$file" "${file}${POSTFIX}"
            echo "Gotowe: ${file}${POSTIX}"
        else 
            echo "Błąd: Nie znaleziono pliku $file" >&2
        fi
    done
fi