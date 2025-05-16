import App from './App';
import './index.scss';
import './aboutUs.scss';

const app = new App();
    window.addEventListener('hashchange', () => handleRoute());

    function handleRoute(){
        let route = window.location.hash;
        if(route == "#/aboutus"){
            document.getElementById("aboutuspage").classList.remove("hidden");
            document.getElementById("aboutUsNav").classList.add("active");
            document.getElementById("homepage").classList.add("hidden");
        } 
        else {
            document.getElementById("aboutuspage").classList.add("hidden");
            document.getElementById("aboutUsNav").classList.remove("active");
            document.getElementById("homepage").classList.remove("hidden");
        }
    }
