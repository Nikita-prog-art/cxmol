https://page.hyoo.ru/#!=3skw_ac25gk

Здравствуйте, меня зовут Дмитрий Карловский и я.. хочу поведать вам о фундаментальной особенности систем типов, которую зачастую или вообще не понимают или понимают не правильно через призму реализации конкретного языка, который ввиду эволюционного развития имеет много атавизмов. Поэтому, даже если вы думаете, что знаете, что такое "вариантность", постарайтесь взглянуть на проблематику свежим взглядом. Начнём мы с самых основ, так что даже новичок всё поймёт. А продолжим без воды, чтобы даже профи было полезно для структурирования своих знаний. Примеры кода будут на псевдоязыке похожем на TypeScript. Потом будут разобраны подходы уже нескольких реальных языков. А если же вы разрабатываете свой язык, то данная статья поможет вам не наступить на чужие грабли.

![а вдруг там лис?](https://habrastorage.org/webt/uz/yw/ly/uzywlybdb47qium0-khvukslzwc.png)

# Аргументы и параметры

**Параметр** - это то, что мы принимаем. Описывая тип параметра мы задаём ограничение на множество типов, которые можно нам передать. Несколько примеров :

```typescript
// параметр функции
function log( id : string | number ) {}

// параметр конструктора
class Logger {
    constructor( readonly id : Natural ) {}
}

// шаблонный параметр
class Node< Id extends Number > {
    id : Id
}
```

**Аргумент** - это то, что мы передаём. В момент передачи аргумент всегда имеет какой-то конкретный тип. Тем не менее, при статическом анализе конкретный тип может быть не известен из-за чего компилятор оперирует опять же ограничениями на тип. Несколько примеров:

```typescript
log( 123 ) // конкретный тип
new Logger( promptStringOrNumber( 'Enter id' ) ) // конкретный тип известен только в рантайме
new Node( 'root' ) // явно некорректный тип, ошибка компиляции
```

# Подтипы

Типы могут могут образовывать иерархию. *Подтип* - это частный случай *надтипа*. Подтип может образовываться путём **сужения** множества возможных значений надтипа. Например, тип Natural является подтипом Integer и Positive. И все трое одновременно являются подтипами Real. В то же время типы Positive и Integer являются пересекающимися, но ни один из них не является сужением другого.

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--ig-M6ikJ--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0bhyx91t97g7yv1uxr1a.png)

Другой способ образовать подтип - **расширить** его, объединив с другим ортогональным ему типом. Например, есть "цветная фигура" имеющая свойство "цвет", а есть "квадрат" имеющий свойство "высота". Объединив эти типы мы получим "цветной квадрат". А добавив "круг" с его "радиусом" можем получить "цветной цилиндр".

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--ImpG5z6H--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/4na2541w568mn8xlqtbl.png)

# Иерархии

Для дальнейшего повествования нам понадобится небольшая иерархия животных и аналогичная ей иерархия клеток.

```typescript
abstract class Animal {}
abstract class Pet extends Animal {}
class Cat extends Pet {}
class Dog extends Pet {}
class Fox extends Animal {}

class AnimalCage { content : Animal }
class PetCage extends AnimalCage { content : Pet }
class CatCage extends PetCage { content : Cat }
class DogCage extends PetCage { content : Dog }
class FoxCage extends AnimalCage { content : Fox }
```

Всё, что ниже на рисунке является сужением типа выше. Клетка с питомцем может содержать лишь домашних животных, но не диких. Клетка с собакой может содержать лишь собак.

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--zk-Gf3bv--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/gl33j98lg3nd985th1jt.png)

# Ковариантность

Самое простое и понятное - это **ограничение надтипа** или ковариантность. В следующем примере параметр функции ковариантен указанному для него типу. То есть функция может принимать как сам этот тип, так и любой его подтип, но не может принимать надтипы или иные типы.

```typescript
function touchPet( cage : PetCage ) : void {
    log( `touch ${cage.content}` )
}

touchPet( new AnimalCage ) // forbid
touchPet( new PetCage ) // allow
touchPet( new CatCage ) // allow
touchPet( new DogCage ) // allow
touchPet( new FoxCage ) // forbid
```

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--ik6Kd2ck--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ys26o8dv5zu4yad1xqpf.png)

Так как мы ничего не меняем в клетке, то спокойно можем передавать функции клетку с кошкой, так как она - не более, чем частный случай клетки с питомцем.

# Контравариантность

Чуть сложнее понять **ограничение подтипа** или контравариантность. В следующем примере параметр функции контравариантен указанному для него типу. То есть функция может принимать как сам этот тип, так и любой его надтип, но не может принимать подтипы или иные типы.

```typescript
function pushPet( cage : PetCage ) : void {
    const Pet = random() > .5 ? Cat : Dog
    cage.content = new Pet
}

pushPet( new AnimalCage ) // allow
pushPet( new PetCage ) // allow
pushPet( new CatCage ) // forbid
pushPet( new DogCage ) // forbid
pushPet( new FoxCage ) // forbid
```

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--hfth2l31--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7ngmvvzz8j1i4cajplmt.png)

Мы не можем передать клетку с кошкой, так как функция может засунуть туда собаку, что не допустимо. А вот клетку с любым животным можно смело передавать, так как и кошку и собаку вполне можно туда помещать.

# Инвариантность

**Ограничение подтипа и надтипа** могут быть одновременно. Такой случай называется инвариантностью. В следующем примере параметр функции инвариантен указанному для него типу. То есть функция может принимать только указанный тип и никакой больше.

```typescript
function replacePet( cage : PetCage ) : void {
    touchPet( cage )
    pushPet( cage )
}

replacePet( new AnimalCage ) // forbid
replacePet( new PetCage ) // allow
replacePet( new CatCage ) // forbid
replacePet( new DogCage ) // forbid
replacePet( new FoxCage ) // forbid
```

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--ISaHUZfZ--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ipl86wwe8h22fes4zevy.png)

Функция `replacePet` наследует ограничения у тех функций, которые она внутри себя использует: у `touchPet` она взяла ограничение на надтип, а у `pushPet` - ограничение на подтип. Если мы передадим ей клетку с любым животным, то она не сможет передать её в функцию touchPet, которая не умеет работать с лисами (дикое животное просто откусит палец). А если передадим клетку с кошкой, то не получится вызвать уже `pushPet`.

# Бивариантность

Нельзя не упомянуть и экзотическое **отсутствие ограничений** - бивариантность. В следующем примере функция может принять любой тип являющийся надтипом или подтипом.

```typescript
function enshurePet( cage : PetCage ) : void {
    if( cage.content instanceof Pet ) return
    pushPet( cage )
}

replacePet( new AnimalCage ) // allow
replacePet( new PetCage ) // allow
replacePet( new CatCage ) // allow
replacePet( new DogCage ) // allow
replacePet( new FoxCage ) // forbid
```

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--WagwzP_o--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/rjeepp0o5mvf4wx9ln6t.png)

В неё можно передать клетку с животным. Тогда она проверит, что в клетке находится питомец, иначе положит внутрь случайного питомца. А можно передать и, например, клетку с кошкой, тогда она просто ничего не сделает.

# Обобщения

Некоторые считают, что вариантность как-то связана с обобщениями. Зачастую потому, что про вариантность часто объясняют на примере обобщённых контейнеров. Однако, во всём повествовании у нас до сих пор не было ни единого обобщения - сплошь конкретные классы:

```typescript
class AnimalCage { content : Animal }
class PetCage extends AnimalCage { content : Pet }
class CatCage extends PetCage { content : Cat }
class DogCage extends PetCage { content : Dog }
class FoxCage extends AnimalCage { content : Fox }
```

Сделано это было, чтобы показать, что проблемы вариантности никак с обобщениями не связаны. Обобщения нужны лишь, чтобы уменьшить копипасту. Например, код выше можно переписать через простое обобщение:

```typescript
class Cage<Animal> { content : Animal }
```

И теперь можно создавать экземпляры любых клеток:

```typescript
const animalCage = new Cage<Animal>()
const petCage = new Cage<Pet>()
const catCage = new Cage<Cat>()
const dogCage = new Cage<Dog>()
const foxCage = new Cage<Fox>()
```

# Декларация ограничений

Обратите внимание, что сигнатуры у всех четырёх ранее приведённых функций совершенно одинаковые:

```
( cage : PetCage )=> void
```

То есть такое описание принимаемых параметров функции не обладает полнотой - по нему нельзя сказать что в функцию можно передавать. Ну разве что однозначно видно, что клетку с лисой передавать в неё точно не стоит.

Поэтому в современных языках есть средства для явного указания какие у параметра ограничения на типы. Например, модификаторы [in](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/in-generic-modifier) и [out](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/out-generic-modifier) в C#:

```typescript
interface ICageIn<in T> { T content { set; } } // contravariant generic parameter
interface ICageOut<out T> { T content { get; } } // covariant generic parameter
interface ICageInOut<T> { T content { get; set; } } // invariant generic parameter
```

К сожалению, в C# для каждого варианта модификаторов необходимо заводить по отдельному интерфейсу. Кроме того, насколько я понял, бивариантность в C# вообще невыразима.

# Выходные параметры

Функции могут не только принимать, но и возвращать значения. В общем случае, возвращаемое значение может быть и не одно. В качестве примера возьмём функцию принимающую клетку с питомцем и возвращающую двух питомцев.

```typescript
function getPets( input : PetCage ) : [ Pet , Pet ] {
    return [ input.content , new Cat ]
}
```

Такая функция эквивалентна функции, принимающей помимо одного входного параметра, ещё и два выходных. 

```typescript
function getPets( input : PetCage , output1 : PetCage , output2 : PetCage ) : void {
    output1.content = input.content
    output2.content = new Cat
}
```

Внешний код выделяет на стеке дополнительную память, чтобы функция положила в неё всё, что хочет вернуть. А по завершении, вызывающий код уже сможет воспользоваться этими контейнерами в своих целях.

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--JPEJBmMG--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wf7lea0r1ma86n517ljq.png)

Из эквивалентности этих двух функций следует, что возвращаемые функцией значения в отличие от параметров всегда контравариантны указанному выходному типу. Ибо функция может в них писать, но не может из них читать.

# Методы объектов

Методы объектов - это такие функции, которые принимают дополнительный указатель на объект в качестве неявного параметра. То есть следующие две функции эквивалентны.

```typescript
class PetCage { 

    pushPet() : void {
        const Pet = random() > .5 ? Cat : Dog
        this.content = new Pet
    }

}
```

```typescript
function pushPet( this : PetCage ) : void {
    const Pet = random() > .5 ? Cat : Dog
    this.content = new Pet
}
```

Однако, важно отметить, что метод, в отличие от обычной функции, является также и членом класса, что является расширением типа. Приводит это к тому, что появляется дополнительное ограничение надтипа, для функций, вызывающих этот метод:

```typescript
function fillPetCage( cage : PetCage ) {
    cage.pushPet()
}
```

![image](https://res.cloudinary.com/practicaldev/image/fetch/s--SX6GRjw2--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hzsnj3msan84hrxennya.png)

Мы не можем передать в неё такой надтип, где метод `pushPet` ещё не определён. Это похоже на случай с инвариантностью тем, что есть ограничение и снизу и сверху. Однако, место определения метода `pushPet` может быть выше по иерархии. И именно там будет ограничение надтипа.

# Принцип Подстановки  Барбары Лисков (LSP)

Многие считают, что отношение надтип-подтип определяется не исходя из упомянутых ранее способов сужения и расширения типа, а возможностью подставить подтип в любое место использования надтипа. По всей видимости, причина этого заблуждения именно в LSP. Однако, давайте прочитаем определение этого принципа внимательно, обратив внимание, что первично, а что вторично:

> Функции, которые используют базовый тип, должны иметь возможность использовать подтипы базового типа, не зная об этом и не нарушая корректность работы программы.

Для неизменяемых (в том числе не ссылающихся на изменяемые) объектов этот принцип выполняется автоматически, так как неоткуда взяться ограничению подтипа.

С изменяемыми же всё сложнее, так как следующие две ситуации являются взаимоисключающими для принципа LSP:

1. У класса `A` есть подкласс `B`, где поле `B::foo` является подтипом `A::foo`.
2. У класса `A` есть метод, который может изменить поле `A::foo`.

Соответственно, остаётся лишь три пути:

1. Запретить объектам при наследовании сужать типы своих полей. Но тогда в клетку для кота вы сможете засовывать и слона.
2. Руководствоваться не LSP, а вариантностью каждого параметра каждой функции в отдельности. Но тогда придётся много думать и объяснять компилятору где какие ограничения на типы.
3. Плюнуть на всё и уйти в ~~монастырь~~ функциональное программирование, где все объекты неизменяемые, а значит параметры их принимающие ковариантны объявленному типу.

# TypeScript

В тайпскрипте логика простая: все параметры функции считаются ковариантными (что не верно), а возвращаемые значения - контравариантными (что верно). Ранее было показано, что параметры функции могут иметь совершенно любую вариантность в зависимости от того, что эта функция с этими параметрами делает. Поэтому получаются такие вот казусы:

```typescript
abstract class Animal { is! : 'cat' | 'dog' | 'fox' }
abstract class Pet extends Animal { is! : 'cat' | 'dog' }

class Cat extends Pet { is! : 'cat' }
class Dog extends Pet { is! : 'dog' }
class Fox extends Animal { is! : 'fox' }

class Cage<Animal> { content! : Animal }

function pushPet( cage : Cage<Pet> ) : void {
    const Pet = Math.random() > .5 ? Cat : Dog
    cage.content = new Pet
}

pushPet( new Cage<Animal>() ) // forbid to push Pet to Animal Cage :-(
pushPet( new Cage<Cat>() ) // allow to push Dog to Cat Cage :-(
```

Чтобы решить эту проблему приходится помогать компилятору довольно нетривиальным кодом:

```typescript
function pushPet<
    PetCage extends Cage<Animal>
>(
    cage: Cage<Pet> extends PetCage ? PetCage : never
): void {
    const Pet = Math.random() > .5 ? Cat : Dog
    cage.content = new Pet
}

pushPet( new Cage<Animal>() ) // allow :-)
pushPet( new Cage<Pet>() ) // allow :-)
pushPet( new Cage<Cat>() ) // forbid :-)
pushPet( new Cage<Dog>() ) // forbid :-)
pushPet( new Cage<Fox>() ) // forbid :-)
```

[**Попробовать онлайн**](https://tinyurl.com/uesu87y)

# FlowJS

FlowJS имеет более продвинутую систему типов. В частности, в [описании типа можно указать его вариантность](https://flow.org/en/docs/types/generics/#toc-variance-sigils) для обобщённых параметров и для полей объектов. На нашем примере с клетками выглядит это примерно так:

```typescript

class Animal {}
class Pet extends Animal {}

class Cat extends Pet {}
class Dog extends Pet {}
class Fox extends Animal {}

class Cage< Animal > { content : Animal }

function touchPet( cage : { +content : Pet } ) : void {
    console.log( `touch ${typeof cage.content}` )
}

function pushPet( cage: { -content: Pet } ): void {
    const Pet = Number((0: any)) > .5 ? Cat : Dog
    cage.content = new Pet
}

function replacePet( cage : { content : Pet } ) : void {
    touchPet( cage )
    pushPet( cage )
}

touchPet( new Cage<Animal> ) // forbid :-)
touchPet( new Cage<Pet> ) // allow :-)
touchPet( new Cage<Cat> ) // allow :-)
touchPet( new Cage<Dog> ) // allow :-)
touchPet( new Cage<Fox> ) // forbid :-)

pushPet( new Cage<Animal> ) // allow :-)
pushPet( new Cage<Pet> ) // allow :-)
pushPet( new Cage<Cat> ) // forbid :-)
pushPet( new Cage<Dog> ) // forbid :-)
pushPet( new Cage<Fox> ) // forbid :-)

replacePet( new Cage<Animal> ) // forbid :-)
replacePet( new Cage<Pet> ) // allow :-)
replacePet( new Cage<Cat> ) // forbid :-)
replacePet( new Cage<Dog> ) // forbid :-)
replacePet( new Cage<Fox>) // forbid :-)
```

[**Попробовать онлайн**](https://tinyurl.com/uak4hne)

Бивариантность тут невыразима. К сожалению, мне не удалось найти способа более удобно задавать вариантность не описывая типы всех полей явно. Например, как-то так:

```
function pushPet( cage: Contra< Cage<Pet> , 'content' > ): void {
    const Pet = Number((0: any)) > .5 ? Cat : Dog
    cage.content = new Pet
}
```

# C Sharp

C# изначально проектировался без какого-либо понимания вариантности. Однако, впоследствии в нём были добавлены in и out модификаторы параметров, что позволило компилятору правильно проверять типы передаваемых аргументов. К сожалению, использовать эти модификаторы опять же не очень удобно.

```csharp
using System;

abstract class Animal {}
abstract class Pet : Animal {}
class Cat : Pet {}
class Dog : Pet {}
class Fox : Animal {}

interface ICageIn<in T> { T content { set; } }
interface ICageOut<out T> { T content { get; } }
interface ICageInOut<T> { T content { get; set; } }

class Cage<T> : ICageIn<T>, ICageOut<T>, ICageInOut<T> { public T content { get; set; } }

public class Program {

	static void touchPet( ICageOut<Pet> cage ) {
		Console.WriteLine( cage.content );
	}

	static void pushPet( ICageIn<Pet> cage ) {
		cage.content = new Dog();
	}

	static void replacePet( ICageInOut<Pet> cage ) {
		touchPet( cage as ICageOut<Pet> );
		pushPet( cage as ICageIn<Pet> );
	}
	
	void enshurePet( Cage<Pet> cage ) {
		if( cage.content is Pet ) return;
		pushPet( cage as ICageIn<Pet> );
	}

	public static void Main() {
		
		var animalCage = new Cage<Animal>();
		var petCage = new Cage<Pet>();
		var catCage = new Cage<Cat>();
		var dogCage = new Cage<Dog>();
		var foxCage = new Cage<Fox>();

		touchPet( animalCage ); // forbid :-)
		touchPet( petCage ); // allow :-)
		touchPet( catCage ); // allow :-)
		touchPet( dogCage ); // allow :-)
		touchPet( foxCage ); // forbid :-)

		pushPet( animalCage ); // allow :-)
		pushPet( petCage ); // allow :-)
		pushPet( catCage ); // forbid :-)
		pushPet( dogCage ); // forbid :-)
		pushPet( foxCage ); // forbid :-)
		
		replacePet( animalCage ); // forbid :-)
		replacePet( petCage ); // allow :-)
		replacePet( catCage ); // forbid :-)
		replacePet( dogCage ); // forbid :-)
		replacePet( foxCage ); // forbid :-)
		
	}

}
```

[**Попробовать онлайн**](https://dotnetfiddle.net/jAx53p)

# Java

К Java возможность переключения вариантности была добавлена довольно поздно и лишь для обобщённых параметров, которые сами-то появились сравнительно недавно. Если же параметр не обобщённый, то беда. 

```java
abstract class Animal {}
abstract class Pet extends Animal {}
class Cat extends Pet {}
class Dog extends Pet {}
class Fox extends Animal {}

class Cage<T> { public T content; }

public class Main
{
	static void touchPet( Cage<? extends Pet> cage ) {
		System.out.println( cage.content );
	}

	static void pushPet( Cage<? super Pet> cage ) {
		cage.content = new Dog();
	}

	static void replacePet(Cage<Pet> cage ) {
		touchPet( cage );
		pushPet( cage );
	}
	
	void enshurePet( Cage<Pet> cage ) {
		if( cage.content instanceof Pet ) return;
		pushPet( cage );
	}
	
	public static void main(String[] args) {
	    
		Cage<Animal> animalCage = new Cage<Animal>();
		Cage<Pet> petCage = new Cage<Pet>();
		Cage<Cat> catCage = new Cage<Cat>();
		Cage<Dog> dogCage = new Cage<Dog>();
		Cage<Fox> foxCage = new Cage<Fox>();

		touchPet( animalCage ); // forbid :-)
		touchPet( petCage ); // allow :-)
		touchPet( catCage ); // allow :-)
		touchPet( dogCage ); // allow :-)
		touchPet( foxCage ); // forbid :-)

		pushPet( animalCage ); // allow :-)
		pushPet( petCage ); // allow :-)
		pushPet( catCage ); // forbid :-)
		pushPet( dogCage ); // forbid :-)
		pushPet( foxCage ); // forbid :-)
		
		replacePet( animalCage ); // forbid :-)
		replacePet( petCage ); // allow :-)
		replacePet( catCage ); // forbid :-)
		replacePet( dogCage ); // forbid :-)
		replacePet( foxCage ); // forbid :-)
	}
}
```

[**Попробовать онлайн**](https://paiza.io/projects/pIBVVcjarSB0j0RJY8iNTw?language=java)

# C++

C++ благодаря мощной системе шаблонов может выразить различные вариантности, но кода, конечно получается много.

```cpp
#include <iostream>
#include <typeinfo>
#include <type_traits>

class Animal {};
class Pet: public Animal {};

class Cat: public Pet {};
class Dog: public Pet {};
class Fox: public Animal {};

template<class T> class Cage { public: T *content; };

template<class T, class = std::enable_if_t<std::is_base_of<Pet, T>::value>>
void touchPet(const Cage<T> &cage) {
    std::cout << typeid(T).name();
}

template<class T, class = std::enable_if_t<std::is_base_of<T, Pet>::value>>
void pushPet(Cage<T> &cage) {
    cage.content = new Dog();
}

void replacePet(Cage<Pet> &cage) {
    touchPet(cage);
    pushPet(cage);
}

int main(void)
{
    Cage<Animal> animalCage {new Fox()};
    Cage<Pet> petCage {new Cat()};
    Cage<Cat> catCage {new Cat()};
    Cage<Dog> dogCage {new Dog()};
    Cage<Fox> foxCage {new Fox()};

    touchPet( animalCage ); // forbid :-)
    touchPet( petCage ); // allow :-)
    touchPet( catCage ); // allow :-)
    touchPet( dogCage ); // allow :-)
    touchPet( foxCage ); // forbid :-)

    pushPet( animalCage ); // allow :-)
    pushPet( petCage ); // allow :-)
    pushPet( catCage ); // forbid :-)
    pushPet( dogCage ); // forbid :-)
    pushPet( foxCage ); // forbid :-)

    replacePet( animalCage ); // forbid :-)
    replacePet( petCage ); // allow :-)
    replacePet( catCage ); // forbid :-)
    replacePet( dogCage ); // forbid :-)
    replacePet( foxCage ); // forbid :-)
 
    return 0;
}
```

[**Попробовать онлайн**](http://cpp.sh/8aqxm)

# D

D не имеет вменяемых средств явного указания вариантности, зато он умеет сам выводить типы исходя из их использования.

```cpp
import std.stdio, std.random;

abstract class Animal {}
abstract class Pet : Animal { string name; }
class Cat : Pet {}
class Dog : Pet {}
class Fox : Animal {}

class Cage(T) { T content; }

void touchPet( PetCage )( PetCage cage ) {
    writeln( cage.content.name );
}

void pushPet( PetCage )( PetCage cage ) {
    cage.content = ( uniform(0,2) > 0 ) ? new Dog() : new Cat();
}

void replacePet( PetCage )( PetCage cage ) {
    touchPet( cage );
    pushPet( cage);
}

void main() {

    Cage!Animal animalCage;
    Cage!Pet petCage;
    Cage!Cat catCage;
    Cage!Dog dogCage;
    Cage!Fox foxCage;

    animalCage.touchPet(); // forbid :-)
    petCage.touchPet(); // allow :-)
    catCage.touchPet(); // allow :-)
    dogCage.touchPet(); // allow :-)
    foxCage.touchPet(); // forbid :-)

    animalCage.pushPet(); // allow :-)
    petCage.pushPet(); // allow :-)
    catCage.pushPet(); // forbid :-)
    dogCage.pushPet(); // forbid :-)
    foxCage.pushPet(); // forbid :-)

    animalCage.replacePet(); // forbid :-)
    petCage.replacePet(); // allow :-)
    catCage.replacePet(); // forbid :-)
    dogCage.replacePet(); // forbid :-)
    foxCage.replacePet(); // forbid :-)

}
```

[**Попробовать онлайн**](https://tinyurl.com/qwxwzqg)

# Эпилог

На этом пока всё. Надеюсь изложенный материал помог вам лучше понять ограничения на типы, и как они реализованы в разных языках. Где-то лучше, где-то хуже, где-то никак, но в целом - так себе. Возможно именно вы разработаете язык, в котором всё это будет реализовано и удобно, и типобезопасно. А пока присоединяйтесь к нашему [телеграм чату, где мы иногда обсуждаем теоретические концепции языков программирования](https://teleg.run/lang_idioms).
