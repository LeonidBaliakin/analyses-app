Manrope.ttf — исходный variable font, лицензия [OFL.txt](OFL.txt).

Manrope-Regular.ttf (wght=400) и Manrope-Bold.ttf (wght=700) — статические
экземпляры этого же файла для офлайн PDF. Созданы fontTools 4.69.1:

```python
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
for name, weight in [('Regular', 400), ('Bold', 700)]:
    font = instantiateVariableFont(TTFont('Manrope.ttf'), {'wght': weight})
    font.save(f'Manrope-{name}.ttf')
```

Flutter UI продолжает использовать variable font. PDF получает отдельные
статические начертания, поскольку его движок не выбирает ось variable font так
же, как Flutter. Шрифт при экспорте не скачивается.
