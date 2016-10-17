######
## for jupyter 
## hakell python node scala
## とりあえず動く
##
#######

FROM centos:7

MAINTAINER koda

USER root
#ホストとやり取りするディレクトリ
RUN mkdir -p  /jupyter_file
VOLUME /jupyter_file
RUN mkdir -p  /root/.jupyter
COPY jupyter_notebook_config.py  /root/.jupyter/



RUN yum update -y
#RUN yum install -y passwd
#RUN yum install -y sudo

#RUN useradd jupyter
#RUN mkdir -p /home/jupyter
#RUN chown jupyter:jupyter /home/jupyter
#RUN echo "jupyter ALL=(ALL) ALL" >> /etc/sudoers.d/jupyter



#コンパイルに必要そうなものをここでインストール
RUN yum -y install git
RUN yum -y groupinstall "Development Tools"
RUN yum -y install readline-devel zlib-devel bzip2-devel sqlite-devel openssl-devel
RUN yum -y install wget

#pyenv(pythonのバージョンを簡単に変更できるツール)
RUN git clone https://github.com/yyuu/pyenv.git ~/.pyenv
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
RUN echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
RUN echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
RUN source ~/.bash_profile


RUN git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
RUN echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile
RUN source ~/.bash_profile


#bashで実行
#python env
RUN /bin/bash -c "source ~/.bash_profile \
  && pyenv install 3.5.1  "


RUN /bin/bash -c "source ~/.bash_profile \
  && pyenv virtualenv 3.5.1 jupyter \
  && pyenv local jupyter \
  && pip install --upgrade pip \
  && pip install jupyter \
  && pip install numpy \
  && pip install pandas \
  && pip install matplotlib \
  && pip install --upgrade 'https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.10.0rc0-cp35-cp35m-linux_x86_64.whl' "

#mecab
RUN rpm -ivh http://packages.groonga.org/centos/groonga-release-1.1.0-1.noarch.rpm
RUN yum install mecab mecab-ipadic mecab-devel -y
RUN /bin/bash -c "source ~/.bash_profile \
  && pyenv local jupyter \
  && pip install mecab-python3 "

#scala
RUN set -x && yum -y install java-1.8.0-openjdk.x86_64  java-1.8.0-openjdk-devel.x86_64 \
&& wget http://downloads.typesafe.com/scala/2.11.6/scala-2.11.6.rpm \
&& rpm -ivh scala-2.11.6.rpm \
&& curl -L -o jupyter-scala https://git.io/vrHhi && chmod +x jupyter-scala && ./jupyter-scala && rm -f jupyter-scala \
&& rm -rf scala-2.11.6.rpm




#zeromq4 install これが一番はまった(ihaskellがこれをいれないとコンパイルできない)
RUN echo '[saltstack-zeromq4]'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'name=Copr repo for zeromq4 owned by saltstack'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'baseurl=https://copr-be.cloud.fedoraproject.org/results/saltstack/zeromq4/epel-7-$basearch/'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'skip_if_unavailable=True'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'gpgcheck=1'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'gpgkey=https://copr-be.cloud.fedoraproject.org/results/saltstack/zeromq4/pubkey.gpg'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'enabled=1'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& echo 'enabled_metadata=1'>>/etc/yum.repos.d/saltstack-zeromq4.repo \
&& yum --enablerepo=saltstack-zeromq4 install -y zeromq zeromq-devel 


#jupyter-node
#node
RUN git clone git://github.com/creationix/nvm.git ~/.nvm
RUN source ~/.nvm/nvm.sh
RUN echo 'if [[ -s ~/.nvm/nvm.sh ]];'  >> ~/.bash_profile
RUN echo ' then source ~/.nvm/nvm.sh'  >> ~/.bash_profile
RUN echo 'fi'  >> ~/.bash_profile
RUN source ~/.bash_profile


RUN set -x&& echo "cd /jupyter_file" >> start.sh \
&& echo "source ~/.bash_profile" >> start.sh \
&& echo "/root/.local/bin/ihaskell install" >> start.sh \
&& echo "stack exec jupyter notebook &" >> start.sh 



RUN /bin/bash -c "source ~/.bash_profile \
  && nvm install 0.12.15 \
  && nvm alias default v0.12.15"





RUN git clone https://github.com/notablemind/jupyter-nodejs.git
RUN mkdir -p ~/.ipython/kernels/nodejs/
RUN /bin/bash -c "source ~/.bash_profile \
  && cd  jupyter-nodejs \
  && npm install && node install.js \
  && make "


#stack exec jupyter -- notebook
RUN wget http://curl.haxx.se/download/curl-7.37.0.tar.bz2 \
&& tar xf curl-7.37.0.tar.bz2 && rm -rf curl-7.37.0.tar.bz2 && cd curl-7.37.0 \
&& ./configure --enable-libcurl-option && make \
&& make install \
&& cd .. &&  rm -rf curl-7.37.0



RUN set -x && yum install -y epel-release \
&& yum -y --nogpgcheck install R 
#&& mkdir -p /usr/share/doc/R-3.3.1/html \



RUN set -x && echo "install.packages(c('repr', 'IRdisplay', 'crayon', 'pbdZMQ', 'devtools') ,repos='https://cran.ism.ac.jp/')" >> start.r \
&& echo "devtools::install_github('IRkernel/IRkernel', force=TRUE)" >> start.r \
&& echo "v<-system2('jupyter', '--version', TRUE,FALSE)" >> start.r \
&& echo "compareVersion(v, '3.0.0')" >> start.r \
&& echo "IRkernel::installspec()" >> start.r \
&& source ~/.bash_profile \
&& mkdir -p /usr/share/doc/R-3.3.1/html \ 
&& R --slave --vanilla < start.r \
&& rm -rf start.r



#haskell
RUN curl -sSL https://s3.amazonaws.com/download.fpcomplete.com/centos/7/fpco.repo | tee /etc/yum.repos.d/fpco.repo
RUN yum -y install stack
RUN stack setup

RUN mkdir -p /root/.stack/global-project
RUN rm -rf /root/.stack/global-project/stack.yaml
RUN echo flags: {} >> /root/.stack/global-project/stack.yaml \
    && echo extra-package-dbs: [] >> /root/.stack/global-project/stack.yaml \
    && echo packages: [] >> /root/.stack/global-project/stack.yaml \
    && echo extra-deps: [] >> /root/.stack/global-project/stack.yaml \
    && echo resolver: lts-6.2 >> /root/.stack/global-project/stack.yaml\
    && stack setup


RUN set -x && stack install haskell-src-exts
RUN set -x \
&& stack install ihaskell zeromq4-haskell \
# && stack install ihaskell \
&&  /bin/bash -c "source ~/.bash_profile \
   /root/.local/bin/ihaskell install "





CMD sh start.sh
