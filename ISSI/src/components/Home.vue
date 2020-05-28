<template>
    <div id = "Home">
        <h1>File Browser</h1>
        <TreeBrowser 
        :node="root"
        @onClick="nodeWasClicked"
            />
    </div>
</template>

<script>
    import TreeBrowser from './TreeBrowser.vue'
    import root from '../root.json'

    export default {
        data() {
            return {
                name: 'Home',
                root,
            }
        },

        methods: {
            nodeWasClicked(node) {
            alert(node.name);
            }
        },

            components: {
                TreeBrowser
            }
        }
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  margin-top: 60px;
}
</style>