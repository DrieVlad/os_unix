#!/bin/bash

GameMap=(" " " " " " " " " " " " " " " " " " " ")

#Определение базовых переменных
InitializationVars() {
  FIFO=GameFIFO
  if [[ ! -p $FIFO ]]
  then
    CheckAdmin=0
  else
    CheckAdmin=1
  fi


}

#Чтение символов
ReadSymbol() {
  local line
  if [[ -n $1 ]]
  then
    WHERE=$1
  else
    unset WHERE
  fi
  
  while true
  do

    if [[ -z $1 ]]
    then
	  echo -n "Ваш ход: "
      read -r line
    else
      read -r line<"$1"
    fi

    if [[ $line =~ ^([1-3])\ ([1-3])$ ]]
    then
      X="${BASH_REMATCH[1]}"
      Y="${BASH_REMATCH[2]}"
	  
    else
      echo "Неправильный ввод - попробуйте снова"
      continue
    fi

    X=$((X-1))
    Y=$((Y-1))
    j=$((X * 3 + Y))

    if [[ ${GameMap[j]} != " " ]]
    then
      WriteSymb "Выберите другую позицию" "$WHERE"
    else
      break
    fi
  done
}

#Удаление файла очереди
CleanFIFO() {
  rm -f $FIFO
}


#Отрисвка игрового поля
DrawMap() {
  clear
  echo " ${GameMap[0]} | ${GameMap[1]} | ${GameMap[2]} "
  echo "---+---+---"
  echo " ${GameMap[3]} | ${GameMap[4]} | ${GameMap[5]}      Write X Y"
  echo "---+---+---"
  echo " ${GameMap[6]} | ${GameMap[7]} | ${GameMap[8]} "
}

#Смена индекса
set_map() {
  j=$((X * 3 + Y))
  GameMap[$j]=$1
}

#Пишем симвоолы
WriteSymb() {
  if [[ -z $2 ]]
  then
    echo "$1"
  else
    echo "$1" >"$2"
  fi
}

#Определяем символ игрока
SymbPlayer(){
  if [[ $CheckAdmin -eq 0 ]]
  then
    Symb='X'
    SymbEnem='O'
  else
    Symb='O'
    SymbEnem='X'
  fi
}

#Игровой цикл
GameCicle() {
  if [[ $CheckAdmin -eq 0 ]]
  then
    DrawMap
    ReadSymbol
	echo "$((X+1)) $((Y+1))" > $FIFO
    set_map $Symb
  fi

  while true
  do
    DrawMap
    echo "Ждем соперника"
    ReadSymbol $FIFO
    set_map $SymbEnem
    CheckGameOver $SymbEnem
    DrawMap
    ReadSymbol
	echo "$((X+1)) $((Y+1))" > $FIFO
    set_map $Symb
    CheckGameOver $Symb
  done

}

#Завершаем игру
GameOver() {
  DrawMap

  if [[ $1 -eq 1 ]]
  then
    echo "Ничья!"
    CleanFIFO
    exit 0
  fi

  if [[ $2 == "$Symb" ]]
  then
    echo "Вы победили, поздравляю!"
  else
    echo "Вы проиграли, попробуйте снова!"
  fi

  CleanFIFO
  exit 0
}

#Проверяем победы или ничью
CheckGameOver() {

  if CheckCol "$1"
  then
    GameOver 0 "$1"
  fi
  
  if CheckRow "$1"
  then
    GameOver 0 "$1"
  fi

  if CheckDiagonals "$1"
  then
    GameOver 0 "$1"
  fi

  if CheckEmpt
  then
    GameOver 1
  fi
}

CheckRow() {
  if [[ ${GameMap[0]} == "$1" ]]
  then
    if [[ ${GameMap[1]} == "$1" ]]
	then
	  if [[ ${GameMap[2]} == "$1" ]]
	  then
        return 0
	  fi
	fi
  fi
  
  if [[ ${GameMap[3]} == "$1" ]]
  then
    if [[ ${GameMap[4]} == "$1" ]]
	then
	  if [[ ${GameMap[5]} == "$1" ]]
	  then
        return 0
	  fi
	fi
  fi
  
  if [[ ${GameMap[6]} == "$1" ]]
  then
    if [[ ${GameMap[7]} == "$1" ]]
	then
	  if [[ ${GameMap[8]} == "$1" ]]
	  then
        return 0
	  fi
	fi
  fi

  return 1
}

CheckCol() {
  if [[ ${GameMap[0]} == "$1" ]]
  then
    if [[ ${GameMap[3]} == "$1" ]]
	then
	  if [[ ${GameMap[6]} == "$1" ]]
	  then
        return 0
	  fi
	fi
  fi
  
  if [[ ${GameMap[1]} == "$1" ]]
  then
    if [[ ${GameMap[4]} == "$1" ]]
	then
	  if [[ ${GameMap[7]} == "$1" ]]
	  then
        return 0
	  fi
	fi
  fi
  
  if [[ ${GameMap[2]} == "$1" ]]
  then
    if [[ ${GameMap[5]} == "$1" ]]
	then
	  if [[ ${GameMap[8]} == "$1" ]]
	  then
        return 0
	  fi
	fi
  fi

  return 1
}

CheckDiagonals() {
  if [[ ${GameMap[4]} != "$1" ]]
  then
    return 1
  fi

  if [[ ${GameMap[0]} == "$1" ]]
  then
    if [[ ${GameMap[8]} == "$1" ]]
	then
      return 0
	fi
  fi

  if [[ ${GameMap[2]} == "$1" ]]
  then
    if [[ ${GameMap[6]} == "$1" ]]
	then
      return 0
	fi
  fi

  return 1
}
CheckEmpt() {
  Busy=0;
  for ((i=0; i<9; i++)) 
  do
    if [[ ${GameMap[$i]} == " " ]]
	then
	  Busy=1
	fi
  done
  return $Busy
}

Initialization() {
  clear
  InitializationVars
  SymbPlayer
  if [[ $CheckAdmin -eq 0 ]]
  then
    mkfifo "$FIFO"

    if mkfifo "$FIFO"
    then
      echo "Error FIFO" >&2
      exit
    fi
  fi
  
  GameCicle
}

Initialization
