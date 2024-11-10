{ pkgs, ...}: {
  env = {
    KUBECONFIG = "kubeconfig";
  };
  scripts = {
    test-chart.exec = ''
      helm uninstall $1 --namespace $1
      helm install $1 \
        charts/$1 \
        --namespace $1 \
        --values charts/$1/values-example.yaml \
        --create-namespace
    '';
  };
  packages = with pkgs; [ minikube ];
}
