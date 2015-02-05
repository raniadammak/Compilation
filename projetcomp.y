/* les tokens ici sont ceux supposes etre renvoyes par l'analyseur lexical
 * A adapter par chacun en fonction de ce qu'il a ecrit dans tp.l
 * Bison ecrase le contenu de tp_y.h a partir de la description de la ligne
 * suivante. C'est donc cette ligne qu'il faut adapter si besoin, pas tp_y.h !
 */
%token IF THEN ELSE AF ADD SUB MUL DIV RELOP VAR TYPE STATIC  DEF RETURN RETURNS IS NEW CLASS EXTENDS YIELD IDC OVERRIDE OPSELEC CST THIS SUPER VOID 
//%token <S> ID	/* voir %type ci-dessous pour le sens de <S> et Cie */
//%token <I> CST
%token ID

%type <T> argL arg programme 

/* indications de precedence d'associativite. Les operateurs sur une meme
 * ligne (separes par un espace) ont la meme priorite. Les ligns sont donnees
 * par precedence croissante d'operateurs.
 */

%nonassoc ret
%nonassoc RELOP
%left ADD SUB
%left MUL DIV
%left OPSELEC



/* voir la definition de YYSTYPE dans main.h 
 * Les indications ci-dessous servent a indiquer a Bison que les "valeurs" $i
 * ou $$ associees a ces non-terminaux doivent utiliser la variante indiquee
 * de l'union YYSTYPE (par exemple la variante D ou S, etc.)
 * La "valeur" associee a un terminal utilise toujours la meme variante
 */

//%type <T> expr exprAr exprC select bexpr class argL decl declL meth meth2 meth3 meth4 methL champ champL param paramL bloc blocF blocP instrL vinstrL message 
%{
#include "tp.h"     /* les definition des types et les etiquettes des noeuds */

extern int yylex();	/* fournie par Flex */
extern void yyerror();  /* definie dans projetcomp.c */
%}

%% 
 /*
 * Attention: on est dans un analyseur ascendant donc on s'occupe des composants
 * d'une construction avant de traiter la construction elle-meme. Dans le cas
 * d'un IF on traitera donc la condition et les parties THEN et ELSE avant
 * de traiter le 'IF' lui-meme. Comme on ne doit evaluer que l'une des deux
 * branches 'then' ou 'else' selon la valeur de la condition, on ne peut pas
 * evaluer les expressions au fur et a mesure qu'on les rencontre puisqu'on ne
 * sait pas si on fait partie d'un IF ou pas. On doit attendre de connaitre
 * l'expression complete pour savoir si telle partie doit etre evaluee ou non.
 *
 * Les macros d'allocation NEW et de nullite NIL sont definies dans tp.h.
 * Leur usage n'est bien sur pas obligatoire, juste conseille !
 *
 * Les definition des types YYSTYPE, VarDecl, VarDeclP, Tree, TreeP et autres
 * sont dans tp.h
 */

 /* "programme" est l'axiome de la grammaire */
programme: classL bloc { $$ = makeTree(OPPROG,2,$1,$2);}
| bloc { $$ = makeTree(OPPROG,2, NULL,$1);}
;

/* Une liste eventuellement vide de définition de classes */
classL : classL class { $$ = makeTree(OPCLASSL,2, $1,$2);}
| class { $$ = makeTree(OPCLASSL,2, NULL,$1);}
; 

/* Déclaration d'une classe */

class : CLASS IDC '(' paramL ')' IS '{' declL '}' { $$ = makeTree(OPCLASS,6, $2, $4, NULL, NULL, NULL, $8); } 
|  CLASS IDC '(' paramL ')' EXTENDS IDC '('argL ')' IS '{' declL '}' { $$ = makeTree(OPCLASS,6, $2, $4, $7, $9, NULL, $13); } 
|  CLASS IDC '(' paramL ')' bloc IS '{' declL '}' { $$ = makeTree(OPCLASS,6,$2, $4, NULL, NULL, $6, $9); } 
|  CLASS IDC '(' paramL ')' EXTENDS IDC '('argL ')' bloc IS '{' declL '}' { $$ = makeTree(OPCLASS,6, $2, $4, $7, $9, $11, $14); } 
;

decl : champL methL { $$ = makeTree(OPDECL,2, $1,$2);}
;

declL : declL decl { $$ = makeTree(OPDECLL,2, $1,$2);}
| decl { $$ = makeTree(OPDECLL,2, NULL,$1);}
;

champL : champ champL { $$ = makeTree(OPCHPL,2, $1,$2);}
| champ { $$ = makeTree(OPCHPL,2, $1,NULL);}
;

methL : meth methL { $$ = makeTree(OPMTHL,2, $1,$2);}
| meth { $$ = makeTree(OPMTHL,2, $1,NULL);}
;

/* Déclaration d'une var */
champ: VAR STATIC ID ':' TYPE ';' { $$ = makeTree(OPCHPSTAT,3, $3,$5,NULL);}
| VAR ID ':' TYPE ';' { $$ = makeTree(OPCHP,3, $2,$4,NULL);}
| VAR STATIC ID ':' TYPE AF expr ';' { $$ = makeTree(OPCHPSTAT,3, $3,$5,$7);}
| VAR ID ':' TYPE AF expr ';' { $$ = makeTree(OPCHP,3, $2,$4,$6);}
;

/* Déclaration d'une méthode */
meth : DEF meth2 { $$ = makeTree(OPMTH,1,$2);}
;

meth2 : ID meth3 { $$ = makeTree(OPMTH2,2,$1,$2);}
| OVERRIDE ID meth3 { $$ = makeTree(OPMTH2OV,2,$2,$3);}
;

meth3 : '(' paramL ')' RETURNS class meth4 { $$ = makeTree(OPMTH3,3,$2,$5,$6);}
;

meth4 : IS bloc { $$ = makeTree(OPMTH4,1,$2);}
| AF expr { $$ = makeTree(OPMTH4,1,$2);}
;

paramL : param paramL { $$ = makeTree(OPPARAML,2,$1,$2);}
| {}
;

param : ID ':' TYPE { $$ = makeTree(OPPARAM,2,$1,$2);}
;

/* Instruction */

instr : expr ';' { $$ = $1;}
| bloc { $$ = $1;}
| ID AF expr ';' { $$ = makeTree(OPINST,3,$1,$2,NULL);}
| select AF expr ';' { $$ = makeTree(OPINST,3,$2,$4,$6);}
| IF expr THEN instr ELSE instr { $$ = makeTree(OPINST,3,$2,$4,$6);}
;

/* Expression */

expr : ID { $$ = $1;}
| select { $$ = $1;}
| CST { $$ = $1;}
| NEW TYPE '(' ')'
| NEW TYPE '(' argL ')'
| expr ADD expr { $$ = makeTree(ADD,2, $1, $3);}
| expr SUB expr { $$ = makeTree(SUB,2, $1, $3);}
| expr MUL expr { $$ = makeTree(MUL,2, $1, $3);}
| expr DIV expr { $$ = makeTree(DIV,2, $1, $3);}
| expr RELOP expr { $$ = makeTree(RELOP,2, $1, $3);}
| '(' expr ')' { $$ = $2;}
| RETURN %prec ret expr
;

select : IDC '.' ID { $$ = makeTree(OPSELEC,2, $1, $3);}
| ID '.' ID { $$ = makeTree(OPSELEC,2, $1, $3);}
| select '.' ID %prec OPSELEC
| message '.' ID %prec OPSELEC
;

argL : expr ',' argL { $$ = makeTree(OPARG,2, $1, $3);} 
| expr { $$ = makeTree(OPARG,2, $1, NULL);} 
;

/*bloc : les deux types */
bloc : '{' blocF '}' { $$ = makeTree(OPBLOC, 2, $1, NULL);} 
| '{' blocP '}' { $$ = makeTree(OPBLOC, 2, $1, NULL);}
| '{' '}'
;

/* bloc fonctionnel */

blocF : blocP YIELD expr { $$ = makeTree(OPBLOC,2, $1, $3);}
;

/* bloc procédural */

blocP : instrL { $$ = makeTree(OPBLOC, 2, $1, NULL);} 
| vinstrL { $$ = makeTree(OPBLOC, 2, $1, NULL);} 
;

instrL : instr instrL  { $$ = makeTree(OPINSTL, 3, $1, $2, NULL);}
| instr { $$ = makeTree(OPINSTL, 3, $1, NULL, NULL);}
;

vinstrL : champ IS instr vinstrL { $$ = makeTree(OPINSTL, 3, $1, $3, $4);}
| champ IS instr { $$ = makeTree(OPINSTL, 3, $1, $3, NULL);}
;




/* message */
message : ID '(' paramL ')' { $$ = makeTree(OPMSG, 2, $1, $3);}
;

/* une declaration de variable ou de fonction, terminee par un ';'. */
decl : ID AF expr ';' { $$ = makeTree(OPDECL, 2, $1, $3);}
;

