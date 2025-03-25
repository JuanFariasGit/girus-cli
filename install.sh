#!/bin/bash

# ASCII Art Banner para o Girus
cat << "EOF"
   ██████╗ ██╗██████╗ ██╗   ██╗███████╗
  ██╔════╝ ██║██╔══██╗██║   ██║██╔════╝
  ██║  ███╗██║██████╔╝██║   ██║███████╗
  ██║   ██║██║██╔══██╗██║   ██║╚════██║
  ╚██████╔╝██║██║  ██║╚██████╔╝███████║
   ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
EOF
echo -e "\nScript de Instalação - Versão 0.1.0\n"

# Verificar se o script está sendo executado como root (sudo)
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ ERRO: Este script não deve ser executado como root ou com sudo."
    echo "   Por favor, execute sem sudo. O script solicitará elevação quando necessário."
    exit 1
fi

# Configuração de variáveis e ambiente
set -e

# Detectar o sistema operacional
case "$(uname -s)" in
    Linux*)     OS="linux";;
    Darwin*)    OS="darwin";;
    CYGWIN*|MINGW*|MSYS*) OS="windows";;
    *)          OS="unknown";;
esac

# Detectar a arquitetura
ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
    x86_64)     ARCH="amd64";;
    amd64)      ARCH="amd64";;
    arm64)      ARCH="arm64";;
    aarch64)    ARCH="arm64";;
    *)          ARCH="unknown";;
esac

echo "Sistema operacional detectado: $OS"
echo "Arquitetura detectada: $ARCH"

# Verificar se o sistema operacional é suportado
if [ "$OS" == "unknown" ]; then
    echo "❌ Sistema operacional não suportado: $(uname -s)"
    exit 1
fi

# Verificar se a arquitetura é suportada
if [ "$ARCH" == "unknown" ]; then
    echo "❌ Arquitetura não suportada: $ARCH_RAW"
    exit 1
fi

# Configurações e variáveis
GIRUS_VERSION="v0.1.0"
BINARY_URL="https://github.com/grupo-girus/girus-cli/releases/download/$GIRUS_VERSION/girus-cli-$OS-$ARCH"
ORIGINAL_DIR=$(pwd)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Função para verificar se o comando curl ou wget está disponível
check_download_tool() {
    if command -v curl &> /dev/null; then
        echo "curl"
    elif command -v wget &> /dev/null; then
        echo "wget"
    else
        echo "none"
    fi
}

# Função para instalar Docker
install_docker() {
    echo "Instalando Docker..."
    
    if [ "$OS" == "linux" ]; then
        # Linux (script de conveniência do Docker)
        echo "Baixando o script de instalação do Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        echo "Executando o script de instalação (será solicitada senha de administrador)..."
        sudo sh get-docker.sh
        
        # Adicionar usuário atual ao grupo docker
        echo "Adicionando usuário atual ao grupo docker..."
        sudo usermod -aG docker $USER
        
        # Iniciar o serviço
        echo "Iniciando o serviço Docker..."
        sudo systemctl enable --now docker
        
        # Limpar arquivo de instalação
        rm get-docker.sh
    
    elif [ "$OS" == "darwin" ]; then
        # MacOS
        echo "No macOS, o Docker Desktop precisa ser instalado manualmente."
        echo "Por favor, baixe e instale o Docker Desktop para Mac:"
        echo "https://docs.docker.com/desktop/mac/install/"
        echo "Após a instalação, reinicie seu terminal e execute este script novamente."
        exit 1
    
    elif [ "$OS" == "windows" ]; then
        # Windows
        echo "No Windows, o Docker Desktop precisa ser instalado manualmente."
        echo "Por favor, baixe e instale o Docker Desktop para Windows:"
        echo "https://docs.docker.com/desktop/windows/install/"
        echo "Após a instalação, reabra o terminal e execute este script novamente."
        exit 1
    fi
    
    # Verificar a instalação
    if ! command -v docker &> /dev/null; then
        echo "❌ Falha ao instalar o Docker."
        echo "Por favor, instale manualmente seguindo as instruções em https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    echo "Docker instalado com sucesso!"
    echo "NOTA: Pode ser necessário reiniciar seu sistema ou fazer logout/login para que as permissões de grupo sejam aplicadas."
}

# Função para instalar Kind
install_kind() {
    echo "Instalando Kind..."
    
    if [ "$OS" == "linux" ] || [ "$OS" == "darwin" ]; then
        # Linux/Mac
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(uname)-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    
    elif [ "$OS" == "windows" ]; then
        # Windows
        echo "Instalação automática do Kind não suportada no Windows."
        echo "Por favor, baixe e instale Kind manualmente:"
        echo "https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        echo "Após a instalação, reabra o terminal e execute este script novamente."
        exit 1
    fi
    
    # Verificar a instalação
    if ! command -v kind &> /dev/null; then
        echo "Falha ao instalar o Kind. Por favor, instale manualmente."
        exit 1
    fi
    
    echo "Kind instalado com sucesso!"
}

# Função para instalar Kubectl
install_kubectl() {
    echo "Instalando Kubectl..."
    
    if [ "$OS" == "linux" ]; then
        # Linux
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    
    elif [ "$OS" == "darwin" ]; then
        # MacOS
        if command -v brew &> /dev/null; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        fi
    
    elif [ "$OS" == "windows" ]; then
        # Windows
        echo "Instalação automática do Kubectl não suportada no Windows."
        echo "Por favor, baixe e instale Kubectl manualmente:"
        echo "https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        echo "Após a instalação, reabra o terminal e execute este script novamente."
        exit 1
    fi
    
    # Verificar a instalação
    if ! command -v kubectl &> /dev/null; then
        echo "Falha ao instalar o Kubectl. Por favor, instale manualmente."
        exit 1
    fi
    
    echo "Kubectl instalado com sucesso!"
}

# Função para verificar se o Docker está em execução
check_docker_running() {
    if docker info &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Verificar se o Girus CLI está no PATH
check_girus_in_path() {
    if command -v girus-cli &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Função para verificar instalações anteriores do Girus CLI
check_previous_install() {
    local previous_install_found=false
    local install_locations=(
        "/usr/local/bin/girus-cli"
        "/usr/bin/girus-cli"
        "$HOME/.local/bin/girus-cli"
        "./girus-cli"
    )
    
    # Verificar instalações anteriores
    for location in "${install_locations[@]}"; do
        if [ -f "$location" ]; then
            echo "⚠️ Instalação anterior encontrada em: $location"
            previous_install_found=true
        fi
    done
    
    # Se uma instalação anterior foi encontrada, perguntar sobre limpeza
    if [ "$previous_install_found" = true ]; then
        read -p "Deseja remover a(s) instalação(ões) anterior(es)? (S/n): " CLEAN_INSTALL
        CLEAN_INSTALL=${CLEAN_INSTALL:-S}
        
        if [[ "$CLEAN_INSTALL" =~ ^[Ss]$ ]]; then
            echo "🧹 Removendo instalações anteriores..."
            
            for location in "${install_locations[@]}"; do
                if [ -f "$location" ]; then
                    echo "Removendo $location"
                    if [[ "$location" == "/usr/local/bin/girus-cli" || "$location" == "/usr/bin/girus-cli" ]]; then
                        sudo rm -f "$location"
                    else
                        rm -f "$location"
                    fi
                fi
            done
            
            echo "✅ Limpeza concluída."
        else
            echo "Continuando com a instalação sem remover versões anteriores."
        fi
    else
        echo "✅ Nenhuma instalação anterior do Girus CLI encontrada."
    fi
}

# Função para baixar e instalar o binário
download_and_install() {
    echo "📥 Baixando o Girus CLI versão $GIRUS_VERSION para $OS-$ARCH..."
    cd "$TEMP_DIR"
    
    # Verificar qual ferramenta de download está disponível
    DOWNLOAD_TOOL=$(check_download_tool)
    
    if [ "$DOWNLOAD_TOOL" == "curl" ]; then
        echo "Usando curl para download..."
        curl -L --progress-bar "$BINARY_URL" -o girus-cli
    elif [ "$DOWNLOAD_TOOL" == "wget" ]; then
        echo "Usando wget para download..."
        wget --show-progress -q "$BINARY_URL" -O girus-cli
    else
        echo "❌ Erro: curl ou wget não encontrados. Por favor, instale um deles e tente novamente."
        exit 1
    fi
    
    # Verificar se o download foi bem-sucedido
    if [ ! -f girus-cli ] || [ ! -s girus-cli ]; then
        echo "❌ Erro: Falha ao baixar o Girus CLI."
        echo "URL: $BINARY_URL"
        echo "Verifique sua conexão com a internet e se a versão $GIRUS_VERSION está disponível."
        exit 1
    fi
    
    # Tornar o binário executável
    chmod +x girus-cli
    
    # Perguntar se o usuário deseja instalar no PATH
    echo "🔧 Girus CLI baixado com sucesso."
    read -p "Deseja instalar o Girus CLI em /usr/local/bin? (S/n): " INSTALL_GLOBALLY
    INSTALL_GLOBALLY=${INSTALL_GLOBALLY:-S}
    
    if [[ "$INSTALL_GLOBALLY" =~ ^[Ss]$ ]]; then
        echo "📋 Instalando o Girus CLI em /usr/local/bin/girus-cli..."
        sudo mv girus-cli /usr/local/bin/
        echo "✅ Girus CLI instalado com sucesso em /usr/local/bin/girus-cli"
        echo "   Você pode executá-lo de qualquer lugar com o comando 'girus-cli'"
    else
        # Copiar para o diretório original
        cp girus-cli "$ORIGINAL_DIR/"
        echo "✅ Girus CLI copiado para o diretório atual: $(realpath "$ORIGINAL_DIR/girus-cli")"
        echo "   Você pode executá-lo com: './girus-cli'"
    fi
}

# Verificar se todas as dependências estão instaladas
verify_all_dependencies() {
    local all_deps_ok=true
    
    # Verificar Docker
    if command -v docker &> /dev/null && check_docker_running; then
        echo "✅ Docker está instalado e em execução."
    else
        echo "❌ Docker não está instalado ou não está em execução."
        all_deps_ok=false
    fi
    
    # Verificar Kind
    if command -v kind &> /dev/null; then
        echo "✅ Kind está instalado."
    else
        echo "❌ Kind não está instalado."
        all_deps_ok=false
    fi
    
    # Verificar Kubectl
    if command -v kubectl &> /dev/null; then
        echo "✅ Kubectl está instalado."
    else
        echo "❌ Kubectl não está instalado."
        all_deps_ok=false
    fi
    
    # Verificar Girus CLI
    if check_girus_in_path; then
        echo "✅ Girus CLI está instalado e disponível no PATH."
    else
        echo "⚠️ Girus CLI não está disponível no PATH."
        all_deps_ok=false
    fi
    
    return $( [ "$all_deps_ok" = true ] && echo 0 || echo 1 )
}

# Iniciar mensagem principal
echo "=== Iniciando instalação do Girus CLI ==="

# Verificar e limpar instalações anteriores
check_previous_install

# ETAPA 1: Verificar pré-requisitos - Docker
echo "=== ETAPA 1: Verificando Docker ==="
if ! command -v docker &> /dev/null; then
    echo "Docker não está instalado."
    read -p "Deseja instalar Docker automaticamente? (Linux apenas) (S/n): " INSTALL_DOCKER
    INSTALL_DOCKER=${INSTALL_DOCKER:-S}
    
    if [[ "$INSTALL_DOCKER" =~ ^[Ss]$ ]]; then
        install_docker
    else
        echo "⚠️ Aviso: Docker é necessário para criar clusters Kind e executar o Girus."
        echo "Por favor, instale o Docker adequado para seu sistema operacional:"
        echo " - Linux: https://docs.docker.com/engine/install/"
        echo " - macOS: https://docs.docker.com/desktop/install/mac-install/"
        echo " - Windows: https://docs.docker.com/desktop/install/windows-install/"
        exit 1
    fi
else
    # Verificar se o Docker está em execução
    if ! docker info &> /dev/null; then
        echo "⚠️ Aviso: Docker está instalado, mas não está em execução."
        read -p "Deseja tentar iniciar o Docker? (S/n): " START_DOCKER
        START_DOCKER=${START_DOCKER:-S}
        
        if [[ "$START_DOCKER" =~ ^[Ss]$ ]]; then
            echo "Tentando iniciar o Docker..."
            if [ "$OS" == "linux" ]; then
                sudo systemctl start docker
                # Verificar novamente
                if ! docker info &> /dev/null; then
                    echo "❌ Falha ao iniciar o Docker. Por favor, inicie manualmente com 'sudo systemctl start docker'"
                    exit 1
                fi
            else
                echo "No macOS/Windows, inicie o Docker Desktop manualmente e execute este script novamente."
                exit 1
            fi
        else
            echo "❌ Erro: Docker precisa estar em execução para usar o Girus. Por favor, inicie-o e tente novamente."
            exit 1
        fi
    fi
    echo "✅ Docker está instalado e em execução."
fi

# ETAPA 2: Verificar pré-requisitos - Kind
echo "=== ETAPA 2: Verificando Kind ==="
if ! command -v kind &> /dev/null; then
    echo "Kind não está instalado."
    read -p "Deseja instalar Kind automaticamente? (S/n): " INSTALL_KIND
    INSTALL_KIND=${INSTALL_KIND:-S}
    
    if [[ "$INSTALL_KIND" =~ ^[Ss]$ ]]; then
        install_kind
    else
        echo "⚠️ Aviso: Kind é necessário para criar clusters Kubernetes e executar o Girus."
        echo "Você pode instalá-lo manualmente seguindo as instruções em: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        exit 1
    fi
else
    echo "✅ Kind já está instalado."
fi

# ETAPA 3: Verificar pré-requisitos - Kubectl
echo "=== ETAPA 3: Verificando Kubectl ==="
if ! command -v kubectl &> /dev/null; then
    echo "Kubectl não está instalado."
    read -p "Deseja instalar Kubectl automaticamente? (S/n): " INSTALL_KUBECTL
    INSTALL_KUBECTL=${INSTALL_KUBECTL:-S}
    
    if [[ "$INSTALL_KUBECTL" =~ ^[Ss]$ ]]; then
        install_kubectl
    else
        echo "⚠️ Aviso: Kubectl é necessário para interagir com o cluster Kubernetes."
        echo "Você pode instalá-lo manualmente seguindo as instruções em: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        exit 1
    fi
else
    echo "✅ Kubectl já está instalado."
fi

# ETAPA 4: Baixar e instalar o Girus CLI
echo "=== ETAPA 4: Instalando Girus CLI ==="
download_and_install

# Voltar para o diretório original
cd "$ORIGINAL_DIR"

# Mensagem final de conclusão
echo ""
echo "===== INSTALAÇÃO CONCLUÍDA ====="
echo ""

# Verificar todas as dependências
verify_all_dependencies
echo ""

# Exibir instruções para próximos passos
cat << EOF
📝 PRÓXIMOS PASSOS:

1. Para criar um novo cluster Kubernetes e instalar o Girus:
   $ girus create cluster

2. Após a criação do cluster, acesse o Girus no navegador:
   http://localhost:8000

3. No navegador, inicie o laboratório Linux de boas-vindas para conhecer 
   a plataforma e começar sua experiência com o Girus!

Obrigado por instalar o Girus CLI!
EOF

exit 0 