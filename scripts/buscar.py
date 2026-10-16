# Busca un elemento en el arbol de pantalla (uiautomator) y devuelve su centro "x y".
# Uso: buscar.py ui.xml texto "Xtream"   |   buscar.py ui.xml editar 2
import re
import sys
import xml.etree.ElementTree as ET

arbol = ET.parse(sys.argv[1])
modo, valor = sys.argv[2], sys.argv[3]
if modo == "texto":
    nodos = [n for n in arbol.iter("node") if n.get("text") == valor]
else:
    campos = [n for n in arbol.iter("node") if n.get("class") == "android.widget.EditText"]
    nodos = [campos[int(valor)]] if int(valor) < len(campos) else []
if not nodos:
    sys.exit(1)
x1, y1, x2, y2 = map(int, re.findall(r"\d+", nodos[0].get("bounds")))
print((x1 + x2) // 2, (y1 + y2) // 2)
