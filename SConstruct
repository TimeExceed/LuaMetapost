# -*- python -*-
import os
import os.path as op
import shutil as sh
import subprocess as sp
import random
from datetime import datetime

env = Environment()
mode = ARGUMENTS.get('mode', 'debug')
env['BUILD_DIR'] = env.Dir('build/%s' % mode)
env['TMP_DIR_PATTERN'] = '$BUILD_DIR/tmp/%s.%s.%s/'
env['RANDOM'] = random.Random()
env['HEADER_DIR'] = env.Dir('$BUILD_DIR/include')
env['BIN_DIR'] = env.Dir('$BUILD_DIR/bin')
env.SetOption('duplicate', 'soft-hard-copy')
env.Decider('MD5')

# helper functions

def newTmpDir(env, usr):
    ts = datetime.utcnow()
    ts = ts.strftime('%Y%m%dT%H%M%S.%f')
    salt = env['RANDOM'].randint(0, 10000)
    d = env.Dir(env['TMP_DIR_PATTERN'] % (usr, ts, salt))
    os.makedirs(d.path)
    return d

env.AddMethod(newTmpDir)

def subDir(env, subd):
    env.SConscript('%s/SConscript' % subd, exports='env')

env.AddMethod(subDir)

_Glob = env.Glob
def Glob(pathname, ondisk=True, source=False, strings=False):
    fs = _Glob(pathname, ondisk, source, strings)
    fs.sort(key=lambda x:x.path)
    return fs
env.Glob = Glob

def symlink(src, dst):
    if op.islink(src):
        src = os.readlink(src)
    if op.isdir(dst):
        base = op.basename(src)
        dst = op.join(dst, base)
    os.symlink(op.abspath(src), dst)

# prepare build dir

def makeBuildDir():
    for d in [env['BUILD_DIR'], env['HEADER_DIR']]:
        d = d.abspath
        if not op.exists(d):
            os.makedirs(d)
        assert op.isdir(d)

def cleanBuildDir():
    buildDir = env['BUILD_DIR'].abspath
    for rt, dirs, files in os.walk(buildDir):
        try:
            dirs.remove('.git')
        except:
            pass
        for f in files:
            f = op.join(rt, f)
            if op.islink(f) or f.endswith('.gcno') or f.endswith('.gcda'):
                os.remove(f)

def firstDirname(p):
    x = p
    y = op.dirname(p)
    while len(y) > 0:
        x = y
        y = op.dirname(x)
    return x

def cloneFile(rt, fn):
    d = op.join(env['BUILD_DIR'].path, rt)
    if not op.exists(d):
        os.makedirs(d)
    os.symlink(op.abspath(op.join(rt, fn)), op.join(d, fn))
    
def cloneWorkSpace():
    buildDir = firstDirname(env['BUILD_DIR'].path)
    paths = os.listdir('.')
    for x in [buildDir, '.git', '.gitignore', '.sconsign.dblite', 'SConstruct']:
        try:
            paths.remove(x)
        except:
            pass
    for x in paths:
        if op.isfile(x):
            cloneFile('', x)
        if op.isdir(x):
            for rt, _, files in os.walk(x):
                for f in files:
                    cloneFile(rt, f)

makeBuildDir()
cleanBuildDir()
cloneWorkSpace()


# for clojure

def cloneInto(dstDir, srcs):
    for x in srcs:
        if x.isdir():
            dstRt = op.join(dstDir, op.basename(x.path))
            if not op.exists(dstRt):
                os.mkdir(dstRt)
            for rt, dirs, files in os.walk(x.path):
                for d in dirs:
                    d = x.rel_path(env.Dir(rt).Dir(d))
                    d = op.join(dstRt, d)
                    if not op.exists(d):
                        os.mkdir(d)
                for f in files:
                    g = x.rel_path(env.Dir(rt).File(f))
                    g = op.join(dstRt, g)
                    symlink(op.join(rt, f), g)
        else:
            symlink(x.path, op.join(dstDir, op.basename(x.path)))

def writeManifest(workdir, kws):
    if 'Manifest' not in kws:
        return None
    items = kws['Manifest']
    fn = op.join(workdir, 'manifest')
    with open(fn, 'w') as f:
        for k, v in items.items():
            f.write('%s: %s\n' % (k, v))
    return fn

def jar(env, target, source, **kwargs):
    def _jar(target, source, env):
        assert len(target) == 1
        dstJar = env.File(target[0])
        
        srcs = env.Flatten([source])
        for x in srcs:
            assert x.exists()

        workdir = env.newTmpDir('clj').path
        
        cloneInto(workdir, srcs)
        manifest = writeManifest(workdir, kwargs)

        tmpJar = op.join(workdir, op.basename(dstJar.path))
        if manifest:
            sp.check_call(['jar', 'cfm', tmpJar, manifest, '-C', workdir, '.'])
        else:
            sp.check_call(['jar', 'cf', tmpJar, '-C', workdir, '.'])
        sp.check_call(['jar', 'i', tmpJar])
        os.link(tmpJar, dstJar.path)
    env.Command(target, source, _jar)
    for x in source:
        if x.isdir():
            for rt, _, files in os.walk(x.abspath):
                for f in files:
                    env.Depends(env.File(target), env.File(op.join(rt, f)))
        else:
            env.Depends(env.File(target), x)

env.AddMethod(jar)

# for C/C++

flags = {
    'CFLAGS': ['--std=c11'],
    'CXXFLAGS': ['--std=c++11'],
    'CCFLAGS': ['-Wall', '-Wfloat-equal',
                '-g', '-gdwarf-4', 
                '-I%s' % env['HEADER_DIR'].path],
    'LINKFLAGS': ['-Wl,-E']}
if mode == 'debug':
    flags['CCFLAGS'] += ['-O0', '--coverage', '-fsanitize=address', '-fvar-tracking-assignments']
    flags['LINKFLAGS'] += ['--coverage', '-fsanitize=address']
elif mode == 'release':
    flags['CCFLAGS'] += ['-O2', '-Werror', '-DNDEBUG']
env.MergeFlags(flags)

_Program = env.Program
def Program(env, target=None, source=None, **kwargs):
    p = _Program(target, source, **kwargs)
    env.Install('$BIN_DIR', p)
    return p
env.AddMethod(Program)

def Header(env, base, files):
    for f in files:
        src = env.File(f).abspath
        d = env.Dir('$HEADER_DIR').Dir(base)
        if not op.exists(d.abspath):
            os.makedirs(d.abspath)
        des = d.File(op.basename(src)).abspath
        os.symlink(src, des)
env.AddMethod(Header)

env['BUILDERS']['Object'] = env['BUILDERS']['SharedObject']
env['BUILDERS']['StaticObject'] = env['BUILDERS']['SharedObject']


# gogogo

env.SConscript('$BUILD_DIR/SConscript', exports='env')
