import json,urllib.request,urllib.parse,time,re,subprocess
def norm(x): return re.sub(r'[\s\-·:：.]','',x.lower())
log=[]
for dom,term,c in json.load(open('tools/appicons.json')):
  r=[]
  for a in range(3):
    try: r=json.load(urllib.request.urlopen('https://itunes.apple.com/search?'+urllib.parse.urlencode({'term':term,'country':c,'entity':'software','limit':5}),timeout=20))['results'];break
    except Exception as e: time.sleep(20)
  time.sleep(3)
  hit=[x for x in r if norm(term)[:2] in norm(x['trackName'])]
  if not hit: log.append(f'MISS {dom} {term} {[x["trackName"] for x in r][:3]}'); continue
  u=hit[0]['artworkUrl512'].replace('512x512bb.jpg','256x256bb.png')
  urllib.request.urlretrieve(u,'/tmp/a.png')
  subprocess.run(['sips','-s','format','png','-z','192','192','/tmp/a.png','--out',f'icons/{dom}.png'],check=True,capture_output=True)
  log.append(f'OK {dom} {hit[0]["trackName"]}')
open('tools/appicons.log','w').write('\n'.join(log)); print('\n'.join(log))
