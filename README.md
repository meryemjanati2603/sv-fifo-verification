# FIFO synchrone en SystemVerilog et son banc de test

Un FIFO (file « premier entré, premier sorti ») de **8 mots de 8 bits**, avec un banc de test auto-vérifiant qui
compare le circuit à un modèle de référence.

## Le circuit (`fifo.sv`)

| Signal | Sens | Rôle |
|---|---|---|
| `clk`, `reset` | entrée | horloge et reset synchrone |
| `wn`, `rn` | entrée | demande d'écriture, demande de lecture |
| `data_in` | entrée | donnée à écrire (8 bits) |
| `data_out` | sortie | donnée lue, disponible au front d'horloge qui suit la lecture |
| `full`, `empty` | sortie | FIFO plein, FIFO vide |

Une écriture sur un FIFO plein et une lecture sur un FIFO vide sont ignorées. Lecture et écriture peuvent avoir lieu
dans le même cycle.

**Les pointeurs ont 4 bits** : les 3 bits du bas donnent l'adresse dans la mémoire (8 cases), le bit du haut compte
les « tours ». Le FIFO est **vide** quand les deux pointeurs sont identiques, et **plein** quand les adresses sont
identiques mais que le nombre de tours est différent.

### Défaut corrigé par rapport à la première version

La première version (`original/fifo_original_3bit_pointers.sv`) avait des pointeurs de 3 bits. Avec seulement 3 bits, on ne
peut pas distinguer un FIFO plein d'un FIFO vide, et son signal `full` passait à 1 dès la première donnée écrite : le
FIFO ne pouvait en réalité contenir qu'une seule valeur. Le banc de test détecte ce défaut (plus de 5000 erreurs sur
l'ancienne version).

## Le banc de test (`tb_fifo.sv`)

1. **Tests dirigés** : lecture sur FIFO vide, remplissage jusqu'à « plein » (8 écritures), écriture sur FIFO plein,
   vidage complet (ordre premier entré, premier sorti), lecture sur FIFO vide.
2. **Test aléatoire** : 5000 cycles d'écritures et de lectures aléatoires (valeurs et moments aléatoires).
3. **Reset au milieu d'un test**.
4. **Modèle de référence** : une file d'attente écrite dans le banc prédit le contenu du FIFO, la valeur de
   `data_out` et les drapeaux `full` et `empty`, et les compare à chaque cycle.
5. **Couverture** : le banc compte les situations importantes qui se sont réellement produites (plein atteint, vide
   atteint, écriture sur plein, lecture sur vide, lecture et écriture simultanées) et signale si l'une n'a jamais eu lieu.

## Lancer la simulation

Avec Icarus Verilog 12 ou plus récent :

```
iverilog -g2012 -o sim fifo.sv tb_fifo.sv
vvp sim
```

Résultat obtenu :

```
Ecritures acceptees : 2353, lectures acceptees : 2345
Couverture : plein atteint 311 cycles, vide atteint 377 cycles
             ecriture sur plein 145 fois, lecture sur vide 176 fois, lecture et ecriture simultanees 1080 fois
PASS : 0 erreur
```

**Le banc détecte des circuits faux.** J'ai introduit volontairement trois bogues, et le banc échoue à chaque fois :
adresse d'écriture sur 2 bits au lieu de 3, lecture autorisée sur FIFO vide, et vide confondu avec plein.

## Limites connues

- Vérifié en simulation uniquement, avec un seul domaine d'horloge.
- Le banc est un banc de test classique (modèle de référence et stimuli aléatoires), pas un environnement UVM.
  Un environnement UVM pour ce FIFO est une suite possible.
- Pas d'assertions SVA : les contrôles sont faits par le banc à chaque cycle.
